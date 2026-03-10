#!/usr/bin/env pwsh
# build_prod.ps1
# สคริปต์ build production ทุก platform
# Usage: .\build_prod.ps1 [-Platform web|apk|appbundle|ios]

param(
  [string]$Platform = "web"
)

$PROD_URL = "https://smlaicloudapi.dedepos.com"
$DART_DEFINE = "--dart-define=BASE_URL=$PROD_URL"

Write-Host "🚀 Building PRODUCTION for platform: $Platform" -ForegroundColor Green
Write-Host "   BASE_URL = $PROD_URL" -ForegroundColor Cyan

switch ($Platform) {
  "web" {
    flutter build web `
      $DART_DEFINE `
      --release `
      --source-maps
    Write-Host "✅ Web build output: build\web\" -ForegroundColor Green
  }
  "apk" {
    flutter build apk `
      $DART_DEFINE `
      --release `
      --obfuscate `
      --split-debug-info=build/debug-info/android
    Write-Host "✅ APK output: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
  }
  "appbundle" {
    flutter build appbundle `
      $DART_DEFINE `
      --release `
      --obfuscate `
      --split-debug-info=build/debug-info/android
    Write-Host "✅ AAB output: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
  }
  "ios" {
    flutter build ios `
      $DART_DEFINE `
      --release `
      --obfuscate `
      --split-debug-info=build/debug-info/ios
    Write-Host "✅ iOS build complete" -ForegroundColor Green
  }
  default {
    Write-Host "❌ Unknown platform: $Platform" -ForegroundColor Red
    Write-Host "   Supported: web, apk, appbundle, ios"
    exit 1
  }
}
