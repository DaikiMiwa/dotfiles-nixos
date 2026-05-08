{
  description = "My NixOS + home-manager dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      ...
    }:
    let
      username = "daiki.miwa"; # ← 自分のユーザー名に書き換える
      linuxSystem = "x86_64-linux";
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      supportedSystems = [ linuxSystem ] ++ darwinSystems;
      unfreePackageNames = [
        "terraform"
      ];

      nixpkgsConfig = {
        allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfreePackageNames;
      };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
        };

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkDevShells =
        system:
        let
          pkgs = pkgsFor system;
          isDarwin = pkgs.stdenv.isDarwin;
          expoPackages =
            with pkgs;
            [
              nodejs_22
              pnpm
              yarn
              bun
              jdk21
              watchman
              eas-cli
              git
            ]
            ++ nixpkgs.lib.optionals (!isDarwin) [
              android-tools
            ];

          expoNew = pkgs.writeShellApplication {
            name = "expo-new";
            runtimeInputs = [
              pkgs.pnpm
            ];
            text = ''
              if [ "$#" -eq 0 ]; then
                echo "Usage: expo-new <app-name> [create-expo-app options]" >&2
                echo "Example: expo-new my-app --template default" >&2
                exit 2
              fi

              exec pnpm create expo-app@latest "$@"
            '';
          };

          expoStart = pkgs.writeShellApplication {
            name = "expo-start";
            runtimeInputs = [
              pkgs.pnpm
            ];
            text = ''
              if [ ! -f package.json ]; then
                echo "expo-start must be run from an Expo project root." >&2
                exit 2
              fi

              exec pnpm expo start "$@"
            '';
          };

          expoDoctor = pkgs.writeShellApplication {
            name = "expo-doctor";
            runtimeInputs = [
              pkgs.pnpm
            ];
            text = ''
              if [ ! -f package.json ]; then
                echo "expo-doctor must be run from an Expo project root." >&2
                exit 2
              fi

              exec pnpm dlx expo-doctor "$@"
            '';
          };

          easLatest = pkgs.writeShellApplication {
            name = "eas-latest";
            runtimeInputs = [
              pkgs.pnpm
            ];
            text = ''
              exec pnpm dlx eas-cli@latest "$@"
            '';
          };

          expoEnv = pkgs.writeShellApplication {
            name = "expo-env";
            runtimeInputs = expoPackages ++ [
              pkgs.coreutils
            ];
            text = ''
              show_command() {
                local label="$1"
                shift
                local command_name="$1"

                if command -v "$command_name" >/dev/null 2>&1; then
                  printf "%s: " "$label"
                  "$@" | head -n 1
                else
                  printf "%s: not found\n" "$label"
                fi
              }

              show_command "Node" node --version
              show_command "pnpm" pnpm --version
              show_command "Yarn" yarn --version
              show_command "Bun" bun --version
              show_command "Watchman" watchman --version

              if command -v eas >/dev/null 2>&1; then
                printf "EAS CLI: "
                env NODE_NO_WARNINGS=1 eas --version 2>/dev/null | tail -n 1
              else
                echo "EAS CLI: not found"
              fi

              if command -v java >/dev/null 2>&1; then
                printf "Java: "
                java -version 2>&1 | head -n 1
              else
                echo "Java: not found"
              fi

              if command -v adb >/dev/null 2>&1; then
                printf "adb: "
                adb version | head -n 1
              else
                echo "adb: not found"
              fi

              printf "JAVA_HOME: %s\n" "''${JAVA_HOME:-unset}"
              printf "ANDROID_HOME: %s\n" "''${ANDROID_HOME:-unset}"
              printf "ANDROID_SDK_ROOT: %s\n" "''${ANDROID_SDK_ROOT:-unset}"
              printf "REACT_NATIVE_PACKAGER_HOSTNAME: %s\n" "''${REACT_NATIVE_PACKAGER_HOSTNAME:-unset}"
            '';
          };
        in
        {
          default = self.devShells.${system}.expo;

          expo = pkgs.mkShell {
            packages = expoPackages ++ [
              expoNew
              expoStart
              expoDoctor
              easLatest
              expoEnv
            ];

            shellHook = ''
              export EXPO_NO_TELEMETRY=1
              export JAVA_HOME=${pkgs.jdk21.home}

              android_sdk_candidates=()
              if [ -n "''${ANDROID_HOME:-}" ]; then
                android_sdk_candidates+=("$ANDROID_HOME")
              fi
              if [ -n "''${ANDROID_SDK_ROOT:-}" ]; then
                android_sdk_candidates+=("$ANDROID_SDK_ROOT")
              fi
              android_sdk_candidates+=("$HOME/Android/Sdk")

              if [ -n "''${WSL_DISTRO_NAME:-}" ] && command -v cmd.exe >/dev/null 2>&1; then
                win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
                if [ -n "$win_user" ]; then
                  android_sdk_candidates+=("/mnt/c/Users/$win_user/AppData/Local/Android/Sdk")
                fi
              fi

              for android_sdk in "''${android_sdk_candidates[@]}"; do
                if [ -d "$android_sdk" ]; then
                  export ANDROID_HOME="$android_sdk"
                  export ANDROID_SDK_ROOT="$android_sdk"
                  export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
                  break
                fi
              done

              echo "Expo dev shell: node $(node --version), pnpm $(pnpm --version), java $(java -version 2>&1 | head -n 1)"
              if [ -n "''${ANDROID_HOME:-}" ]; then
                echo "Android SDK: $ANDROID_HOME"
              else
                echo "Android SDK: not detected; Expo Go and tunnel mode still work."
              fi
              echo "Helpers: expo-new, expo-start, expo-doctor, eas-latest, expo-env"
            '';
          };

          astro = pkgs.mkShell {
            packages =
              with pkgs;
              [
                nodejs_22
                pnpm
                bun
                wrangler
                git
                gh
                playwright-test
                playwright-driver.browsers
              ]
              ++ nixpkgs.lib.optionals (!isDarwin) [
                chromium
              ];

            shellHook = ''
              export ASTRO_TELEMETRY_DISABLED=1
              export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
              export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
              export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
              echo "Astro dev shell: node $(node --version), pnpm $(pnpm --version), wrangler $(wrangler --version)"
            '';
          };
        };

      mkHome =
        system:
        let
          pkgs = pkgsFor system;
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/home.nix
          ];
          extraSpecialArgs = {
            inherit username homeDirectory;
            isWSL = false;
          };
        };

      homeConfigurationName = system: if system == linuxSystem then username else "${username}-${system}";

      mkChecks =
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          home-activation = self.homeConfigurations.${homeConfigurationName system}.activationPackage;
        }
        // nixpkgs.lib.optionalAttrs (system == linuxSystem) {
          format-nix =
            pkgs.runCommand "nixfmt-check"
              {
                nativeBuildInputs = [
                  pkgs.nixfmt-rfc-style
                ];
                src = self;
              }
              ''
                cd "$src"
                nixfmt --check $(find . -name '*.nix' -type f | sort)
                touch "$out"
              '';
          nixos-wsl = self.nixosConfigurations.nixos-wsl.config.system.build.toplevel;
        };
    in
    {
      devShells = forAllSystems mkDevShells;

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);

      checks = forAllSystems mkChecks;

      homeConfigurations = {
        ${username} = mkHome linuxSystem;
      }
      // builtins.listToAttrs (
        map (system: {
          name = "${username}-${system}";
          value = mkHome system;
        }) darwinSystems
      );

      # WSL 用の NixOS 設定
      nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = {
          inherit username unfreePackageNames;
        };
        modules = [
          nixos-wsl.nixosModules.default
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {
              inherit username;
              homeDirectory = "/home/${username}";
              isWSL = true;
            };
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };
    };
}
