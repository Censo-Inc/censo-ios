
#!/bin/bash

set -eo pipefail

IPA="Vault.ipa"

if [[ $APP == 'approver' ]]; then
  IPA="Guardian.ipa"
fi

xcrun altool --upload-app -t ios -f build/"$IPA" -u "$APPLEID_USERNAME" -p "$APPLEID_PASSWORD" --verbose
