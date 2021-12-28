#!/bin/sh
fix() {
   FILE=$1
   NEWNAME=$2
   base=$(basename "$FILE")
   basefilename=${base%.*}
   libname=${basefilename#lib*}
   dir=$(dirname "$FILE")

   echo "$dir == /opt/local/lib"
   if [ "$dir" == "/opt/local/lib" ]; then
       newname="@executable_path/../libs/lib$libname.dylib"
       echo "install_name_tool -change $g $newname $NEWNAME"
       install_name_tool -change "$FILE" "$newname" "$NEWNAME"
   fi
}

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    BASEFILENAME=${BASE%.*}
    LIBNAME=${BASEFILENAME#lib*}
    NEWNAME="libs/lib$LIBNAME.dylib"
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
    FILES=$(find "/opt/local/lib" -type f -name "*.dylib")
    for f in $FILES
    do
        fixup $f
    done
    
    FILES=$(find "/opt/local/lib" -type l -name "*.dylib")
    for f in $FILES
    do
        BASE=$(basename "$f")
        BASEFILENAME=${BASE%.*}
        LIBNAME=${BASEFILENAME#lib*}
        NEWNAME="libs/lib$LIBNAME.dylib"
        echo "cp -a $f $NEWNAME"
        cp -a $f $NEWNAME
    done
}
fixup_all