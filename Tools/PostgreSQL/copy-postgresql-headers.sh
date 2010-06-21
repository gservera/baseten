CP=/bin/cp
MKDIR=/bin/mkdir
PRIVATE_HEADERS="$BUILT_PRODUCTS_DIR/$PRIVATE_HEADERS_FOLDER_PATH"

for x in $ARCHS
do
    if [ ! -e "$PRIVATE_HEADERS/postgresql/$x" ]
    then
        "$MKDIR" -p "$PRIVATE_HEADERS/postgresql/$x"

        for y in pg_config.h pg_config_os.h ecpg_config.h
        do
            "$CP" -R "$BUILD_DIR/Release/BaseTen-PostgreSQL/$x/include/$y" "$PRIVATE_HEADERS/postgresql/$x/$y"
        done
    fi
done
