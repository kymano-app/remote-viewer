#!/bin/sh
fix() {
   FILE=$1
   NEWNAME=$2
   base=$(basename "$FILE")
   newname="\$ORIGIN/../libs/$base"
   echo "--set-rpath \$ORIGIN/../libs/ $NEWNAME"
   patchelf --set-rpath "\$ORIGIN/../libs/" "$NEWNAME"
}

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    NEWNAME="libs/$BASE"
    echo "cp $FILE $NEWNAME"
    cp "$FILE" "$NEWNAME"
    LIST=$(patchelf --print-needed $FILE | grep lib | grep -v "ld-linux" | grep -v "ld-2" | grep -v "libc.so")
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done
}

fixup_all () {
    readarray -t EXCLUDE_ARR_FILES < "exclude_files.txt";
    readarray -t EXCLUDE_ARR_PATHES < "exclude_files.txt";
    echo "EXCLUDE_ARR_FILES::: ${EXCLUDE_ARR_FILES[@]}"
    echo "EXCLUDE_ARR_PATHES::: ${EXCLUDE_ARR_PATHES[@]}"
    ARCH=$1
    ARCH_DIR="aarch64-linux-gnu";
    if [ "$ARCH" == "amd64" ]; then
        ARCH_DIR="x86_64-linux-gnu"
    fi

    LIST=$(patchelf --print-needed src/remote-viewer | grep lib | grep -v "ld-linux" | grep -v "ld-2" | grep -v "libc.so")
    NEWNAME="src/remote-viewer"
    for FILE in $LIST
    do
        CONTAIN_EXCLUDE = '0'
        for EXCLUDE in "${EXCLUDE_ARR_FILES[@]}"; do
            echo "EXCLUDE ??? $EXCLUDE" == "$FILE"
            if [[ "$EXCLUDE" == "$FILE" ]]; then
                CONTAIN_EXCLUDE = '1'
            fi
        done
        echo "CONTAIN_EXCLUDE:::$CONTAIN_EXCLUDE : $FILE"
        if [[ $CONTAIN_EXCLUDE == '0' ]]; then
            fix $FILE $NEWNAME
        fi
    done

    mkdir "libs"
    FILES=$(find "/lib64/" -type l -regex ".*.so.*" | grep -v "ld-linux" | grep -v "ld-2" | grep -v "libc.so")
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done

    FILES=$(find "/lib64/" -type f -regex ".*.so.*" | grep -v "ld-linux" | grep -v "ld-2" | grep -v "libc.so")
    for FILE in $FILES
    do
        CONTAIN_EXCLUDE = '0'
        for EXCLUDE in "${EXCLUDE_ARR_PATHES[@]}"; do
            echo "EXCLUDE ??? $EXCLUDE" == "$FILE"
            if [[ "$EXCLUDE" == "$FILE" ]]; then
                CONTAIN_EXCLUDE = '1'
            fi
        done
        echo "CONTAIN_EXCLUDE:::$CONTAIN_EXCLUDE : $FILE"
        if [[ $CONTAIN_EXCLUDE == '0' ]]; then
            fixup $FILE
        fi
    done
}
fixup_all $1