# Lens Retail — Flutter App

This repository contains the Flutter `lib/` sources for the Lens Retail mobile app.

What I added:
- A GitHub Actions workflow to build release APKs automatically: `.github/workflows/flutter_build.yml`.

How to get an APK (recommended):

1. Push this project to a GitHub repository (create a new repo and push the `~/Downloads/lib` folder).
2. On GitHub, open the **Actions** tab — the `Build Flutter APK` workflow will run on push to `main` or `master`.
3. After the workflow completes, download the `flutter-apks` artifact from the workflow run; it contains one or more APKs under `build/app/outputs/flutter-apk/`.

Local build (if you prefer locally):

```bash
# ensure Flutter SDK in PATH (example)
export PATH="$HOME/.flutter_sdk/bin:$PATH"
cd ~/Downloads/lib
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
# APK(s) will be in build/app/outputs/flutter-apk/
```

Notes:
- Update `lib/core/config/app_config.dart` with production `apiBaseUrl` and `apiKey` before releasing.
- The CI workflow uses Android SDK components and will produce split APKs for each ABI.

If you want, I can also create a Git repo for you in this folder and help push it to GitHub.
