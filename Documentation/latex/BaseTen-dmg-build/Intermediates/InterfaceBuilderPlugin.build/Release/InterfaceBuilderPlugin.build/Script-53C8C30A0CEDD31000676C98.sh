#!/bin/sh
BASETEN_FRAMEWORK_PATH="../Frameworks/BaseTen.framework/Versions/A/BaseTen"
BASETENAPPKIT_FRAMEWORK_PATH="../Frameworks/BaseTenAppKit.framework/Versions/A/BaseTenAppKit"

install_name_tool \
	-change "@executable_path/$BASETEN_FRAMEWORK_PATH" \
		"@loader_path/../../../$BASETEN_FRAMEWORK_PATH" \
	"$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/$BASETENAPPKIT_FRAMEWORK_PATH"

install_name_tool \
	-change "@executable_path/$BASETEN_FRAMEWORK_PATH" \
		"@loader_path/$BASETEN_FRAMEWORK_PATH" \
	-change "@executable_path/$BASETENAPPKIT_FRAMEWORK_PATH" \
		"@loader_path/$BASETENAPPKIT_FRAMEWORK_PATH" \
	"$TARGET_BUILD_DIR/$EXECUTABLE_PATH"

