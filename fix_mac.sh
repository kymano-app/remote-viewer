#!/bin/sh
fix() {
   FILE=$1
   NEWNAME=$2
   libname=$(basename "$FILE")
   dir=$(dirname "$FILE")

   echo "$dir == /opt/local/lib"
   if [ "$dir" == "/opt/local/lib" ]; then
       newname="@executable_path/../libs/$libname"
       echo "install_name_tool -change $g $newname $NEWNAME"
       install_name_tool -change "$FILE" "$newname" "$NEWNAME"
   fi
}

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    NEWNAME="libs/$BASE"
    echo "cp $FILE $NEWNAME"
    cp "$FILE" "$NEWNAME"
    echo "install_name_tool -id @executable_path/../$NEWNAME $NEWNAME"
    install_name_tool -id "@executable_path/../$NEWNAME" "$NEWNAME"
    LIST=$(otool -L "$FILE" | tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done
}

fixup_all () {
    LIST=$(otool -L src/remote-viewer| tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    NEWNAME="src/remote-viewer"
    for FILE in $LIST
    do
        fix $FILE $NEWNAME
    done

    mkdir "libs"
    FILES=$(find "/opt/local/lib" -type f -name "*.so" -o -name "*.dylib")
    for f in $FILES
    do
        fixup $f
    done
    
    FILES=$(find "/opt/local/lib" -type l -name "*.so" -o -name "*.dylib")
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done
}
fixup_all