#!/bin/sh
ICON_FOLDER_PATH="$PROJECT_DIR"/../Resources/BaseTenFrameworkIcon

if [ ! -e "$ICON_FOLDER_PATH" ]
then
	ditto -xk "$PROJECT_DIR"/../Resources/BaseTenFrameworkIcon.zip "$ICON_FOLDER_PATH" "$PROJECT_DIR"/../Resources/
fi
sh "$PROJECT_DIR"/../Tools/set_icon.sh "$ICON_FOLDER_PATH" "$TARGET_BUILD_DIR"/"$WRAPPER_NAME"

