#!/bin/bash

echo "Locating dSYMs"
pushd "$PWD/build/Vault.xcarchive/dSYMs/"
echo "Found dSYMs"
zip -r "vault-dSYMs.zip" "."
echo "Created dSYMs zip"
mv "vault-dSYMs.zip" "../../../vault-dSYMs.zip"
popd

echo "dSYMs zipped: vault-dSYMs.zip"

curl -F "DsymFile=@vault-dSYMs.zip" "https://app.raygun.com/dashboard/$RAYGUN_APPLICATION_ID/settings/symbols?authToken=$RAYGUN_ACCESS_TOKEN"

rm "vault-dSYMs.zip"
