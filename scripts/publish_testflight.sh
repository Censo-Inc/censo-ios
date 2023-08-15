
#!/bin/bash

set -eo pipefail

IPA="Vault.ipa"

xcrun altool --upload-app -t ios -f build/"$IPA" -u "$APPLEID_USERNAME" -p "$APPLEID_PASSWORD" --verbose
