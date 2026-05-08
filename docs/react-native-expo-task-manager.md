# React Native / Expo Task Manager チュートリアル

このメモは、Tech Insider の "How to Build a Mobile App with React Native: Complete Tutorial from Setup to App Store (2026)" を、このNixOS-WSL環境のdevShellで進めるための手順です。

元記事:
https://tech-insider.org/react-native-tutorial-mobile-app-complete-guide-2026/

公式資料:

- create-expo-app: https://docs.expo.dev/more/create-expo/
- EAS CLI: https://docs.expo.dev/eas/cli/
- Expo環境変数: https://docs.expo.dev/guides/environment-variables/
- Development builds: https://docs.expo.dev/develop/development-builds/create-a-build/

## 使う環境

通常のHome Manager環境にはReact Native / Expo用ツールを入れません。作業するプロジェクトでdevShellに入ります。

```bash
nix develop ~/dotfiles-nixos#expo -c zsh
```

`nix develop`だけで入るとbashになるため、普段のzsh/starshipプロンプトを使う場合は`-c zsh`を付けます。Home Manager適用後は、作業プロジェクト内で`expo-dev`を実行しても同じdevShellに入れます。

direnvを使う場合は、プロジェクト直下に`.envrc`を置くと現在のzsh/starshipのままdevShellを読み込めます。

```bash
echo 'use flake ~/dotfiles-nixos#expo' > .envrc
direnv allow
```

このdevShellには次を入れています。

- Node.js 22
- pnpm / Yarn / Bun
- JDK 21
- Watchman
- Git
- Android platform-tools (`adb`)
- EAS CLI (`eas`)
- 補助コマンド: `expo-new`, `expo-start`, `expo-doctor`, `eas-latest`, `expo-env`

確認:

```bash
expo-env
```

## WSLでの前提

Android Studio、Android SDK、エミュレータはWindows側に入れるのが扱いやすいです。WSL側ではExpo Go、実機、またはWindows側エミュレータへ`adb`で接続して確認します。

Linux/WSLではiOSシミュレータやXcodeのローカルビルドは使えません。iOSはExpo Goでの確認、またはEAS Buildを使います。

devShellは次の順でAndroid SDKを探し、見つかった場合は`ANDROID_HOME`と`ANDROID_SDK_ROOT`を自動設定します。

1. 既存の`ANDROID_HOME`
2. 既存の`ANDROID_SDK_ROOT`
3. WSL側の`~/Android/Sdk`
4. WSL上で見えるWindows側の`/mnt/c/Users/<Windowsユーザー>/AppData/Local/Android/Sdk`

自動検出されない場合は、プロジェクトの`.envrc`などで明示します。

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
```

## プロジェクト作成

記事はExpo managed workflowとExpo Router構成で進めます。`expo-template-blank-typescript`を使うと`App.tsx`中心の空テンプレートになり、記事の`app/`ディレクトリ構成にはなりません。

```bash
expo-new TaskManager
cd TaskManager
```

SDKやテンプレートを明示したい場合は、`create-expo-app`のオプションをそのまま渡します。

```bash
expo-new TaskManager --template default
```

記事で使う主要ライブラリを入れます。

```bash
pnpm expo install expo-router@4 @react-navigation/native @react-navigation/native-stack @react-navigation/bottom-tabs react-native-screens react-native-safe-area-context
pnpm expo install @react-native-async-storage/async-storage expo-status-bar expo-font
```

テストまで進める場合:

```bash
pnpm add -D jest @testing-library/react-native @testing-library/jest-native jest-expo
```

## 作るディレクトリ

記事のTask Managerアプリでは、おおむね次の構成を作ります。

```text
TaskManager/
  app/
    (tabs)/
      _layout.tsx
      index.tsx
      settings.tsx
    task/
      [id].tsx
      new.tsx
    _layout.tsx
  components/
    TaskCard.tsx
    FilterBar.tsx
    TaskForm.tsx
  hooks/
    useTasks.ts
    useTheme.ts
  services/
    api.ts
    storage.ts
  types/
    task.ts
  __tests__/
```

## 実行

```bash
expo-start
```

Expo GoでQRコードを読むか、Android実機/エミュレータを使う場合はMetroの画面で`a`を押します。WSLとスマートフォンが同じネットワークでつながらない場合は、Tunnelモードを使います。

```bash
expo-start --tunnel
```

## API接続

記事では`EXPO_PUBLIC_API_URL`を使ってAPIの向き先を切り替えます。ローカルのモックAPIやExpressサーバーを使う場合は、プロジェクト直下に`.env.local`を作ります。

```bash
EXPO_PUBLIC_API_URL=http://localhost:3000
```

実機からWSL上のAPIへアクセスする場合、`localhost`はスマートフォン自身を指します。PCのLAN IP、Expo tunnel、または外部のモックAPI URLを使います。

`EXPO_PUBLIC_`で始まる環境変数はアプリに埋め込まれるため、秘密情報は入れません。

## テスト

```bash
pnpm jest --watch
pnpm jest --ci --coverage
```

記事ではComponent testとReducer testを追加します。まず`TaskCard`などのUIコンポーネント、次にタスク状態を扱うReducerをテストします。

## EAS Build

ExpoアカウントにログインしてEAS設定を作ります。

```bash
eas login
eas build:configure
```

Nixpkgsの`eas`が古いと表示された場合だけ、公式最新のEAS CLIを一時実行する`eas-latest`を使います。

```bash
eas-latest login
eas-latest build:configure
```

開発ビルドに進む場合は、Expo Goの代わりになる開発クライアントを入れます。

```bash
pnpm expo install expo-dev-client
eas build --platform android --profile development
```

AndroidのプレビューAPK:

```bash
eas build --platform android --profile preview
```

本番ビルド:

```bash
eas build --platform all --profile production
```

iOSを本番配布するにはApple Developer Program、AndroidをGoogle Playへ出すにはGoogle Play Developerアカウントが必要です。

## 注意点

- Expo CLIはプロジェクトローカルのものを`pnpm expo ...`で使います。
- EAS CLIはdevShellに入れているので`eas ...`で使えます。
- 環境確認はdevShell内で`expo-env`、プロジェクト確認はプロジェクト直下で`expo-doctor`を使います。
- AsyncStorageに秘密情報を保存しません。認証トークンなどは`expo-secure-store`を検討します。
- `EXPO_PUBLIC_`で始まる環境変数はアプリに埋め込まれるため、秘密情報を入れません。
- Windows側Android StudioのSDKを使う場合、SDKパスと`adb`接続方法は環境ごとに調整が必要です。
