
#!/bin/bash

set -eo pipefail

IPA="Censo.ipa"

if [[ $APP == 'approver' ]]; then
  IPA="Approver.ipa"
fi

xcrun altool --upload-app -t ios -f build/"$IPA" -u "$APPLEID_USERNAME" -p "$APPLEID_PASSWORD" --verbose
