#!/bin/sh

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    BASEFILENAME=${BASE%.*}
    LIBNAME=${BASEFILENAME#lib*}
    NEWNAME="libs/$LIBNAME.dylib"
    echo "cp $FILE $NEWNAME"
    cp "$FILE" "$NEWNAME"
    echo "install_name_tool -id @executable_path/../$NEWNAME $NEWNAME"
    install_name_tool -id "@executable_path/../$NEWNAME" "$NEWNAME"
    LIST=$(otool -L "$FILE" | tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    for g in $LIST
    do
        base=$(basename "$g")
        basefilename=${base%.*}
        libname=${basefilename#lib*}
        dir=$(dirname "$g")

        echo "$dir == /opt/local/lib"
        if [ "$dir" == "/opt/local/lib" ]; then
            newname="@executable_path/../libs/$libname.dylib"
            echo "install_name_tool -change $g $newname $NEWNAME"
            install_name_tool -change "$g" "$newname" "$NEWNAME"
        fi
    done
}

fixup_all () {
    LIST=$(otool -L src/remote-viewer| tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    NEWNAME="src/remote-viewer"
    for g in $LIST
    do
        base=$(basename "$g")
        basefilename=${base%.*}
        libname=${basefilename#lib*}
        dir=$(dirname "$g")

        echo "$dir == /opt/local/lib"
        if [ "$dir" == "/opt/local/lib" ]; then
            newname="@executable_path/../libs/$libname.dylib"
            echo "install_name_tool -change $g $newname $NEWNAME"
            install_name_tool -change "$g" "$newname" "$NEWNAME"
        fi
    done

    mkdir "libs"
    FILES=$(find "/opt/local/lib" -type f -maxdepth 1 -name "*.dylib")
    for f in $FILES
    do
        fixup $f
    done
    
    FILES=$(find "/opt/local/lib" -type l -maxdepth 1 -name "*.dylib")
    for f in $FILES
    do
        BASE=$(basename "$f")
        BASEFILENAME=${BASE%.*}
        LIBNAME=${BASEFILENAME#lib*}
        NEWNAME="libs/$LIBNAME.dylib"
        echo "cp -a $f libs/$NEWNAME"
        cp -a $f libs/
    done
}
fixup_all