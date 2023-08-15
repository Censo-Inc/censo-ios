#!/bin/bash

set -eo pipefail

xcodebuild -project "Vault.xcodeproj" \
            -scheme "Vault (Integration)" \
            -destination platform="iOS Simulator,OS=15.0,name=iPhone 11" \
            clean test | xcpretty
