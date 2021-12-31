#!/bin/sh
fix() {
   FIX_FILE=$1
   NEWNAME=$2
   base=$(basename "$FIX_FILE")
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
    LIST=$(patchelf --print-needed $FILE | grep lib)
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done
}

fixup_all () {
    ARCH=$1
    ARCH_DIR="aarch64-linux-gnu";
    if [ "$ARCH" == "amd64" ]; then
        ARCH_DIR="x86_64-linux-gnu"
    fi

    BIN_LIST=$(ls -1 bin/)
    for BIN in $BIN_LIST
    do
        LIB_LIST=$(patchelf --print-needed bin/$BIN | grep lib)
        for LIB in $LIB_LIST
        do
            fix $LIB "bin/$BIN"
        done
    done

    mkdir "libs"
    FILES=$(find "/lib64/" -type l -regex ".*.so.*" | grep -v ".*.\(pyc\|py\)")
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done

    FILES=$(find "/lib64/" -type f -regex ".*.so.*" | grep -v ".*.\(pyc\|py\)")
    for FILE in $FILES
    do
        fixup $FILE
    done

    if [ "$ARCH" == "arm64" ]; then
        cp /lib/ld-* libs/
    fi
    
}
fixup_all $1