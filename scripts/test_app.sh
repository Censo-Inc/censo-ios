#!/bin/bash


set -eo pipefail

APP="censo"
TESTPLATFORM="iOS Simulator,OS=17.0,name=iPhone 11"
#Other TESTPLATFORMS available on the CI IOS Agent
# TESTPLATFORM="iOS,name=Censo iPhone 11 TXK"
# TESTPLATFORM="iOS,name=Censo iPhone Xr TXK"
# TESTPLATFORM="iOS,name=Censo iPhone SE TXK"
#

while [[ $# -gt 0 ]]
do
key="$1"


case $key in
    -t|--testplatform)
    TESTPLATFORM="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--app)
    APP="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac

done





if [[ $APP == "approver" ]]; then
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Approver (Integration)" \
              -destination platform="$TESTPLATFORM" \
              clean test | xcpretty
else
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Censo (Integration)" \
              -destination platform="$TESTPLATFORM" \
              clean test | xcpretty
fi
