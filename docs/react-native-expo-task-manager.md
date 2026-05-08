# React Native / Expo Task Manager チュートリアル

このメモは、Tech Insider の "How to Build a Mobile App with React Native: Complete Tutorial from Setup to App Store (2026)" を、このNixOS-WSL環境のdevShellで進めるための手順です。

元記事:
https://tech-insider.org/react-native-tutorial-mobile-app-complete-guide-2026/

## 使う環境

通常のHome Manager環境にはReact Native / Expo用ツールを入れません。作業するプロジェクトでdevShellに入ります。

```bash
nix develop /home/daiki.miwa/dotfiles-nixos#expo -c zsh
```

`nix develop`だけで入るとbashになるため、普段のzsh/starshipプロンプトを使う場合は`-c zsh`を付けます。Home Manager適用後は、作業プロジェクト内で`expo-dev`を実行しても同じdevShellに入れます。

direnvを使う場合は、プロジェクト直下に`.envrc`を置くと現在のzsh/starshipのままdevShellを読み込めます。

```bash
echo 'use flake /home/daiki.miwa/dotfiles-nixos#expo' > .envrc
direnv allow
```

このdevShellには次を入れています。

- Node.js 22
- pnpm / Yarn / Bun
- JDK 21
- Watchman
- Android platform-tools (`adb`)
- EAS CLI (`eas`)

確認:

```bash
node --version
npm --version
pnpm --version
java -version
adb version
eas --version
```

## WSLでの前提

Android Studio、Android SDK、エミュレータはWindows側に入れるのが扱いやすいです。WSL側ではExpo Go、実機、またはWindows側エミュレータへ`adb`で接続して確認します。

Linux/WSLではiOSシミュレータやXcodeのローカルビルドは使えません。iOSはExpo Goでの確認、またはEAS Buildを使います。

Android SDKをWSL側の`~/Android/Sdk`に置いた場合、devShellが`ANDROID_HOME`と`ANDROID_SDK_ROOT`を自動設定します。Windows側SDKを使う場合は、必要に応じてプロジェクトの`.envrc`やシェルでSDKパスを設定します。

## プロジェクト作成

記事はExpo managed workflowとExpo Router構成で進めます。`expo-template-blank-typescript`を使うと`App.tsx`中心の空テンプレートになり、記事の`app/`ディレクトリ構成にはなりません。

```bash
pnpm create expo-app@latest TaskManager
cd TaskManager
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
pnpm expo start
```

Expo GoでQRコードを読むか、Android実機/エミュレータを使う場合はMetroの画面で`a`を押します。WSLとスマートフォンが同じネットワークでつながらない場合は、Tunnelモードを使います。

```bash
pnpm expo start --tunnel
```

## API接続

記事では`EXPO_PUBLIC_API_URL`を使ってAPIの向き先を切り替えます。ローカルのモックAPIやExpressサーバーを使う場合は、プロジェクト直下に`.env.local`を作ります。

```bash
EXPO_PUBLIC_API_URL=http://localhost:3000
```

実機からWSL上のAPIへアクセスする場合、`localhost`はスマートフォン自身を指します。PCのLAN IP、Expo tunnel、または外部のモックAPI URLを使います。

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
- AsyncStorageに秘密情報を保存しません。認証トークンなどは`expo-secure-store`を検討します。
- `EXPO_PUBLIC_`で始まる環境変数はアプリに埋め込まれるため、秘密情報を入れません。
- Windows側Android StudioのSDKを使う場合、SDKパスと`adb`接続方法は環境ごとに調整が必要です。
