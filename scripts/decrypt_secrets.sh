#!/bin/sh
set -eo pipefail

gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Censo_Mobile_Production_AppStore.mobileprovision ./.github/secrets/Censo_Mobile_Production_AppStore.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Censo_Mobile_Demo_AppStore.mobileprovision ./.github/secrets/Censo_Mobile_Demo_AppStore.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Censo_Mobile_Dev_AppStore.mobileprovision ./.github/secrets/Censo_Mobile_Dev_AppStore.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/ios_distribution.p12 ./.github/secrets/ios_distribution.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/ios_development.p12 ./.github/secrets/ios_development.p12.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Censo_Mobile_Development.mobileprovision ./.github/secrets/Censo_Mobile_Development.mobileprovision.gpg
gpg --quiet --batch --yes --decrypt --passphrase="$IOS_KEYS" --output ./.github/secrets/Censo_Mobile_Demo_2_AppStore.mobileprovision ./.github/secrets/Censo_Mobile_Demo_2_AppStore.mobileprovision.gpg

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

cp ./.github/secrets/Censo_Mobile_Production_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Censo_Mobile_Production_AppStore.mobileprovision
cp ./.github/secrets/Censo_Mobile_Demo_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Censo_Mobile_Demo_AppStore.mobileprovision
cp ./.github/secrets/Censo_Mobile_Dev_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Censo_Mobile_Dev_AppStore.mobileprovision
cp ./.github/secrets/Censo_Mobile_Development.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Censo_Mobile_Development.mobileprovision
cp ./.github/secrets/Censo_Mobile_Demo_2_AppStore.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/Censo_Mobile_Demo_2_AppStore.mobileprovision

security create-keychain -p "" build.keychain
security import ./.github/secrets/ios_distribution.p12 -t agg -k ~/Library/Keychains/build.keychain -P "" -A
security import ./.github/secrets/ios_development.p12 -t agg -k ~/Library/Keychains/build.keychain -P "" -A

security list-keychains -s ~/Library/Keychains/build.keychain
security default-keychain -s ~/Library/Keychains/build.keychain
security unlock-keychain -p "" ~/Library/Keychains/build.keychain

security set-key-partition-list -S apple-tool:,apple: -s -k "" ~/Library/Keychains/build.keychain


# To encrypt certs and profiles use the following command:
# gpg --symmetric --cipher-algo AES256 YOUR_CERTIFICATE.p12
