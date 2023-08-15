#!/bin/bash

set -eo pipefail

ENVIRONMENT="production"
PUBLISH=false

while [[ $# -gt 0 ]]
do
key="$1"


case $key in
    -e|--environment)
    ENVIRONMENT="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--publish)
    PUBLISH=true
    shift # past argument
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac

done


# Setup environment

export RAYGUN_ACCESS_TOKEN="YXRhQHBlcHBlcmVkc29mdHdhcmUuY29tOkxLSjEyM3BvaWFzZA=="

if [[ $ENVIRONMENT == 'production' ]]; then
  export SCHEME="Vault"
  export CONFIGURATION="Release"
  export PROVISIONING_PROFILE="Vault AppStore"
  export RAYGUN_APPLICATION_ID="282j3o2"
elif [[ $ENVIRONMENT == 'integration' ]]; then
  export ICON_RIBBON="Dev"
  export SCHEME="Vault (Integration)"
  export CONFIGURATION="Release (Integration)"
  export PROVISIONING_PROFILE="Vault Integration AppStore"
  export RAYGUN_APPLICATION_ID="283703j"
elif [[ $ENVIRONMENT == 'staging' ]]; then
  export ICON_RIBBON="Preprod"
  export SCHEME="Vault (Staging)"
  export CONFIGURATION="Release (Staging)"
  export PROVISIONING_PROFILE="Vault Staging AppStore"
  export RAYGUN_APPLICATION_ID="283706g"
else
  echo "Unknown environment. Use one of 'integration', 'staging', or 'production'"
  exit 1
fi

# Read AppleID credentials

LINE_NUMBER=0
while read line; do
  if [[ $LINE_NUMBER == 0 ]]; then
    export APPLEID_USERNAME="${line}"
  elif [[ $LINE_NUMBER == 1 ]]; then
    export APPLEID_PASSWORD="${line}"
  else
    break
  fi

  LINE_NUMBER=$((LINE_NUMBER+1))
done < "apple_credentials"

if [[ -z "$APPLEID_USERNAME" ]] || [[ -z "$APPLEID_PASSWORD" ]]; then
  echo "Could not find Apple ID credentials. Make sure the 'apple_credentials' file contains your app-specific username and password"
  exit 1
fi

echo "Running CI steps..."

if [[ ! -z "$ICON_RIBBON" ]]; then
  ./scripts/modify_icon.sh
fi

./scripts/archive_app.sh

./scripts/upload_dsyms.sh

export EXPORT_OPTIONS_PLIST="Vault/ExportOptions.plist"
./scripts/export_ipa.sh

if [[ $PUBLISH == true ]]; then
   ./scripts/publish_testflight.sh
fi

git checkout Vault/Assets.xcassets/AppIcon.appiconset/.
