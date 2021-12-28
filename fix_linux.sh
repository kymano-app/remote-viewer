#!/bin/sh

fix() {
   FILE=$1
   NEWNAME=$2
   base=$(basename "$FILE")
   newname="\$ORIGIN/../libs/$base"
   echo "patchelf --replace-needed $FILE $newname $NEWNAME"
   patchelf --replace-needed "$FILE" "$newname" "$NEWNAME"
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
    LIST=$(patchelf --print-needed src/remote-viewer | grep lib)
    NEWNAME="src/remote-viewer"
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done

    mkdir "libs"
    FILES=$(find "/lib/aarch64-linux-gnu/" -type f -maxdepth 1 -regex ".*.so.*")
    for f in $FILES
    do
        fixup $f
    done

    FILES=$(find "/lib/aarch64-linux-gnu/" -type l -maxdepth 1  -regex ".*.so.*")
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done
}
fixup_all