#!/bin/bash

if which sentry-cli >/dev/null; then
  echo "sentry-cli is installed"
else 
  echo "installing sentry cli"
  curl -sL https://sentry.io/get-cli/ | sh 
fi

if which sentry-cli >/dev/null; then
   echo "uploading symbols to sentry"
   export SENTRY_ORG=censo
   ERROR=$(sentry-cli debug-files upload --include-sources "$PWD/build/Censo.xcarchive/dSYMs/" 2>&1 >/dev/null)
   if [ ! $? -eq 0 ]; then
      echo "warning: sentry-cli - $ERROR"
   else
      echo "successfully uploaded symbols to sentry"
   fi
else
   echo "warning: sentry-cli not installed, download from https://github.com/getsentry/sentry-cli/releases"
fi

