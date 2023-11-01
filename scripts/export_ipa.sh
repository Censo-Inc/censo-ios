#!/bin/bash

set -eo pipefail

xcodebuild -archivePath $PWD/build/Censo.xcarchive \
            -exportOptionsPlist $EXPORT_OPTIONS_PLIST \
            -exportPath $PWD/build \
            -exportArchive | xcpretty
