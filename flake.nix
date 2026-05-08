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
        in
        {
          default = self.devShells.${system}.expo;

          expo = pkgs.mkShell {
            packages =
              with pkgs;
              [
                nodejs_22
                pnpm
                yarn
                bun
                jdk21
                watchman
                eas-cli
              ]
              ++ nixpkgs.lib.optionals (!isDarwin) [
                android-tools
              ];

            shellHook = ''
              export EXPO_NO_TELEMETRY=1
              export JAVA_HOME=${pkgs.jdk21.home}
              if [ -d "$HOME/Android/Sdk" ]; then
                export ANDROID_HOME="$HOME/Android/Sdk"
                export ANDROID_SDK_ROOT="$ANDROID_HOME"
                export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
              fi
              echo "Expo dev shell: node $(node --version), pnpm $(pnpm --version), java $(java -version 2>&1 | head -n 1)"
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
