#!/bin/bash

set -eo pipefail

#Declare variables and set default values
APP=""
TESTPLATFORM="iOS Simulator,OS=17.0,name=iPhone 11"
#If using a physical phone set TESTPLATFORM="iOS,name=<name of phone>"
#
LOGGING=false
LOGFILE=""
OUTPUT_OPTS=""
#
SKIPTESTS="none"
#SKIPTESTS="test://com.apple.xcode/Censo/CensoUITests"


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
    	-l|--logging)
    	LOGGING=true
    	shift # past argument
    	;;
    	*)    # unknown option
    	shift # past argument
    	;;
	esac
done

if [ $LOGGING = true ]; then
	LOGFILE="$APP-output.xml"
	OUTPUT_OPTS="tee /dev/tty | xcpretty --report junit --output $LOGFILE"
else
	OUTPUT_OPTS="xcpretty"
fi


if [[ $APP == "approver" ]]; then
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Approver (Integration)" \
              -destination platform="$TESTPLATFORM" \
	      -skip-testing "$SKIPTESTS" \
              clean test |  eval "$OUTPUT_OPTS"
else
  xcodebuild -project "Censo.xcodeproj" \
              -scheme "Censo (Integration)" \
              -destination platform="$TESTPLATFORM" \
	      -skip-testing "$SKIPTESTS" \
              clean test | eval "$OUTPUT_OPTS"
fi
