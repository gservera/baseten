CP=/bin/cp
FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/BaseTen Assistant.app/Contents/Frameworks/"

if [ ! -d "$BUILT_PRODUCTS_DIR/BaseTen.ibplugin" ]
then
    ib_plugin="$SRCROOT/../InterfaceBuilderPlugin/build/$BUILD_STYLE/BaseTen.ibplugin"
    if [ -d "$ib_plugin" ]
    then
        "$CP" -a -f -v "$ib_plugin" "$BUILT_PRODUCTS_DIR"
    else
        echo "Didn't find BaseTen.ibplugin!"
        exit 1
    fi
fi

exit 0
