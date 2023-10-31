#!/bin/bash

set -eo pipefail

if [[ $APP == "approver" ]]; then
  xcodebuild -project "Vault.xcodeproj" \
              -scheme "Guardian (Integration)" \
              -destination platform="iOS Simulator,OS=17.0,name=iPhone 11" \
              clean test | xcpretty
else
  xcodebuild -project "Vault.xcodeproj" \
              -scheme "Vault (Integration)" \
              -destination platform="iOS Simulator,OS=17.0,name=iPhone 11" \
              clean test | xcpretty
fi
