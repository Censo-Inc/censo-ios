#!/bin/bash

set -eo pipefail

IFS=$'\n'

function generateIcon() {
    RIBBON_PATH="./.icon/${ICON_RIBBON}.png"
    IMAGE_PATH=$1
    WIDTH=$(identify -format %w $IMAGE_PATH)

    mkdir -p "./.icon/resized"

    convert "${RIBBON_PATH}" -resize $WIDTHx$WIDTH "./.icon/resized/${ICON_RIBBON}.${WIDTH}.png"
    echo "Created .icon/resized/${ICON_RIBBON}.${WIDTH}.png"

    composite "./.icon/resized/${ICON_RIBBON}.${WIDTH}.png" "${IMAGE_PATH}" "${IMAGE_PATH}"
    echo "Modified ${IMAGE_PATH}"
}

if [[ $APP == "approver" ]]; then
  ICON_FILES=$(find "./Censo/Assets.xcassets/AppIcon2.appiconset" -name "*.png")
else
  ICON_FILES=$(find "./Censo/Assets.xcassets/AppIcon.appiconset" -name "*.png")
fi

if [ "${ICON_RIBBON}" != "" ]; then
    for ICON in $ICON_FILES; do
        generateIcon $ICON
    done
fi
