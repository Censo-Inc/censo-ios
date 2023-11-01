#!/bin/bash

set -eo pipefail

if [[ $APP == "approver" ]]; then
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Approver (Integration)" \
              -destination platform="iOS Simulator,OS=17.0,name=iPhone 11" \
              clean test | xcpretty
else
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Censo (Integration)" \
              -destination platform="iOS Simulator,OS=17.0,name=iPhone 11" \
              clean test | xcpretty
fi
