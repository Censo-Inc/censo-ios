#!/bin/bash

set -eo pipefail

commit_count=$(git rev-list --no-merges --count HEAD)
legacy_merge_count=26
export BUILD_NUMBER=$((commit_count + legacy_merge_count))

xcodebuild -project "Censo.xcodeproj" \
            -scheme "${SCHEME}" \
            -configuration "${CONFIGURATION}" \
            -sdk iphoneos \
            -archivePath $PWD/build/Censo.xcarchive \
            CODE_SIGN_STYLE="Manual" \
            DEVELOPMENT_TEAM="VN5U64MGYX" \
            CODE_SIGN_IDENTITY="Apple Distribution: Censo, Inc. (VN5U64MGYX)" \
            PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE}" \
            CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
            clean archive | xcpretty
