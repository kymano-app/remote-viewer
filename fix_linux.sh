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
    LIST=$(patchelf --print-needed $FILE | grep lib | grep -v "ld-linux" | grep -v "ld-2")
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

    LIST=$(patchelf --print-needed src/remote-viewer | grep lib | grep -v "ld-linux" | grep -v "ld-2")
    NEWNAME="src/remote-viewer"
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done

    mkdir "libs"
    FILES=$(find "/lib64/" -type f -maxdepth 1 -regex ".*.so.*" | grep -v "ld-linux" | grep -v "ld-2")
    for f in $FILES
    do
        fixup $f
    done

    FILES=$(find "/lib64/" -type l -maxdepth 1  -regex ".*.so.*" | grep -v "ld-linux" | grep -v "ld-2")
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done
}
fixup_all $1