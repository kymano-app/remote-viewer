#!/bin/sh
fix() {
   OLD_LIB_PATH=$1
   CHANGEABLE_FILE=$2
   LIB_NAME=$(basename "$OLD_LIB_PATH")
   LIB_DIR=$(dirname "$OLD_LIB_PATH")

   sudo chown runner $CHANGEABLE_FILE
   echo "LIB_DIR = $LIB_DIR / ${LIB_DIR:0:18}"
   if [[ "$LIB_DIR" == "/opt/local/lib" || ${LIB_DIR:0:18} == "/opt/local/libexec" ]]; then
       NEW_RELATIVE_LIB_PATH="@executable_path/../libs/$LIB_NAME"
       echo "install_name_tool -change $OLD_LIB_PATH $NEW_RELATIVE_LIB_PATH $CHANGEABLE_FILE"
       install_name_tool -change "$OLD_LIB_PATH" "$NEW_RELATIVE_LIB_PATH" "$CHANGEABLE_FILE"
   fi
}

fixup () {
    FILE=$1
    BASE=$(basename "$FILE")
    NEW_LIB_PATH="libs/$BASE"
    ls -l $FILE
    rm -rf $NEW_LIB_PATH
    echo "cp $FILE $NEW_LIB_PATH"
    cp "$FILE" "$NEW_LIB_PATH"
    sudo chown runner $NEW_LIB_PATH
    ls -l $NEW_LIB_PATH

    echo "install_name_tool -id @executable_path/../$NEW_LIB_PATH $NEW_LIB_PATH"
    install_name_tool -id "@executable_path/../$NEW_LIB_PATH" "$NEW_LIB_PATH"
    LIBS_LIST=$(otool -L "$FILE" | tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    for LIB in $LIBS_LIST
    do
        fix $LIB $NEW_LIB_PATH
    done
}

fixup_all () {
    LIB_LIST=$(otool -L src/remote-viewer| tail -n +2 | cut -d ' ' -f 1 | awk '{$1=$1};1')
    CHANGEABLE_FILE="src/remote-viewer"
    for LIB in $LIB_LIST
    do
        fix $LIB $CHANGEABLE_FILE
    done

    mkdir "libs"

    FILES=$(find -E "/opt/local/lib" -type l  -iregex '.*\.(dylib|so)')
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp -a $f $NEWNAME"
        ls -l $f 
        cp -a $f $NEWNAME
        ls -l $NEWNAME
    done

    FILES=$(find -E "/opt/local/libexec" -type l  -iregex '.*\.(dylib|so)')
    for f in $FILES
    do
        BASE=$(basename "$f")
        NEWNAME="libs/$BASE"
        echo "cp $f $NEWNAME"
        ls -l $f 
        cp -a $f $NEWNAME
        ls -l $NEWNAME
    done

    LIB_LIST=$(find -E "/opt/local/lib" -type f  -iregex '.*\.(dylib|so)')
    for LIB in $LIB_LIST
    do
        fixup $LIB
    done


    LIB_LIST=$(find -E "/opt/local/libexec" -type f  -iregex '.*\.(dylib|so)')
    for LIB in $LIB_LIST
    do
        fixup $LIB
    done
    
}
fixup_all