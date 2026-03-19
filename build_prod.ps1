#!/usr/bin/env pwsh
# build_prod.ps1
# Usage:
#   .\build_prod.ps1 -Platform web              # PRODUCTION (default)
#   .\build_prod.ps1 -Platform web -Env dev     # DEV
#   .\build_prod.ps1 -Platform web -Deploy no   # Build only, no deploy

param(
  [string]$Platform = "web",
  [ValidateSet("prod","dev")]
  [string]$Env = "prod",
  [ValidateSet("yes","no")]
  [string]$Deploy = "yes"
)

if ($Env -eq "dev") {
  $BASE_URL        = "https://api.dev.dedepos.com"
  $FIREBASE_PROJECT= "account-seaandhill-dev"
  $ENV_LABEL       = "DEV"
  $LABEL_COLOR     = "Yellow"
  $DEPLOY_URL      = "https://account-seaandhill-dev.web.app"
} else {
  $BASE_URL        = "https://api.dedepos.com"
  $FIREBASE_PROJECT= "account-seaandhill"
  $ENV_LABEL       = "PRODUCTION"
  $LABEL_COLOR     = "Green"
  $DEPLOY_URL      = "https://account-seaandhill.web.app"
}

$DART_DEFINE = "--dart-define=BASE_URL=$BASE_URL"

Write-Host ""
Write-Host "===============================================" -ForegroundColor $LABEL_COLOR
Write-Host "  Building [$ENV_LABEL] | platform: $Platform" -ForegroundColor $LABEL_COLOR
Write-Host "  BASE_URL = $BASE_URL"                         -ForegroundColor Cyan
Write-Host "  Firebase project: $FIREBASE_PROJECT"          -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor $LABEL_COLOR
Write-Host ""

switch ($Platform) {
  "web" {
    flutter build web $DART_DEFINE --release
    Write-Host "Build done: build\web\" -ForegroundColor Green
  }
  "apk" {
    flutter build apk $DART_DEFINE --release --obfuscate --split-debug-info=build/debug-info/android
    Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
  }
  "appbundle" {
    flutter build appbundle $DART_DEFINE --release --obfuscate --split-debug-info=build/debug-info/android
    Write-Host "AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
  }
  "ios" {
    flutter build ios $DART_DEFINE --release --obfuscate --split-debug-info=build/debug-info/ios
    Write-Host "iOS build complete" -ForegroundColor Green
  }
  default {
    Write-Host "Unknown platform: $Platform (supported: web, apk, appbundle, ios)" -ForegroundColor Red
    exit 1
  }
}

if ($Platform -eq "web" -and $Deploy -eq "yes") {
  Write-Host ""
  Write-Host "Deploying [$ENV_LABEL] to Firebase project: $FIREBASE_PROJECT ..." -ForegroundColor $LABEL_COLOR
  firebase deploy --only hosting --project $FIREBASE_PROJECT
  if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Deployed OK -> $DEPLOY_URL" -ForegroundColor $LABEL_COLOR
  } else {
    Write-Host "Firebase deploy failed." -ForegroundColor Red
  }
}

