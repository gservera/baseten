#!/bin/sh
#
# Copies items from per project build directories (if they exist) to this project's build directory,
# so they can be copied by other build phases.
#

BASE_TEN_FRAMEWORK="$PROJECT_DIR/../build/$BUILD_STYLE/BaseTen.framework"

if [ -e "$BASE_TEN_FRAMEWORK" ] && [ "$BASE_TEN_FRAMEWORK" -nt "$BUILT_PRODUCTS_DIR/BaseTen.framework" ]
then
	rm -rf "$BUILT_PRODUCTS_DIR/BaseTen.framework"
	cp -pfR "$BASE_TEN_FRAMEWORK" "$BUILT_PRODUCTS_DIR"
fi


BASE_TEN_APPKIT_FRAMEWORK="$PROJECT_DIR/../BaseTenAppKit/build/$BUILD_STYLE/BaseTenAppKit.framework"

if [ -e "$BASE_TEN_APPKIT_FRAMEWORK" ] && [ "$BASE_TEN_APPKIT_FRAMEWORK" -nt "$BUILT_PRODUCTS_DIR/BaseTenAppKit.framework" ]
then
	rm -rf "$BUILT_PRODUCTS_DIR/BaseTenAppKit.framework"
	cp -pfR "$BASE_TEN_APPKIT_FRAMEWORK" "$BUILT_PRODUCTS_DIR"
fi



