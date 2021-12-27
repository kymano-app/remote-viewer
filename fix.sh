#!/bin/sh

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    BASEFILENAME=${BASE%.*}
    LIBNAME=${BASEFILENAME#lib*}
    echo "cp $FILE libs/$BASE"
    cp "$FILE" "libs/$BASE"
    echo "install_name_tool -id @executable_path/../libs/$LIBNAME.dylib libs/$LIBNAME.dylib"
    install_name_tool -id "@executable_path/../libs/$LIBNAME.dylib" "libs/$LIBNAME.dylib"
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
            echo "install_name_tool -change $g $newname libs/$BASE"
            install_name_tool -change "$g" "$newname" "libs/$BASE"
        fi
    done
}

fixup_all () {
    fixup "src/remote-viewer"
    mkdir "libs"
    FILES=$(find "/opt/local/lib" -type f -maxdepth 1 -name "*.dylib")
    for f in $FILES
    do
        fixup $f
    done
}
pwd
fixup_all