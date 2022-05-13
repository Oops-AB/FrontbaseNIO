#! /bin/bash

OS=$(uname)

if [[ -f /Library/Frameworks/FBCAccess.framework/FBCAccess ]]; then
    FRONTBASE_FRAMEWORK=/Library/Frameworks/FBCAccess.framework
fi

IFS=':' read -ra FRONTBASE_DIRS <<< "/Library/FrontBase:/Library:/usr/local/FrontBase:/usr/local:/usr:/opt:/var"
for DIRECTORY in "${FRONTBASE_DIRS[@]}"; do
    if [[ -d "$DIRECTORY" ]]; then
        IFS='\0' read -ra DIRECTORIES <<< "$(find "$DIRECTORY" -name libFBCAccess.a -print0 2> /dev/null)"
        if [[ -n $DIRECTORIES ]]; then
            FRONTBASE_DIRECTORY="$(dirname "$(dirname "$DIRECTORIES")")"
            break
        fi
    fi
done

if [[ -n "$FRONTBASE_DIRECTORY" ]]; then
    LIBRARY_DIRECTORY="$(dirname "$DIRECTORIES")"
    IFS='\0' read -ra HEADER_FILES <<< "$(find "$(dirname "$FRONTBASE_DIRECTORY")" -name FBCAccess.h -print0 2> /dev/null)"
    if [[ -n "$HEADER_FILES" ]]; then
        INCLUDE_DIRECTORY="$(dirname "$(dirname "$HEADER_FILES")")"
    fi
fi

if [[ -z "$LIBRARY_DIRECTORY" ]] || [[ -z "$INCLUDE_DIRECTORY" ]]; then
    echo "Could not find any FrontBase installed in either of ${FRONTBASE_DIRS[*]}"
    exit 1
else
    echo "Found FrontBase installation in $FRONTBASE_DIRECTORY"
fi

IFS=':' read -ra CONFIG_DIRS <<< "$(pkg-config --variable pc_path pkg-config)"
for DIRECTORY in "${CONFIG_DIRS[@]}"; do
    if [[ -f "$DIRECTORY/FBCAccess.pc" ]]; then
        PKG_CONFIG_PATH="$DIRECTORY/FBCAccess.pc"
        break
    fi
done

if [[ -z "$PKG_CONFIG_PATH" ]]; then
    echo "No pkgConfig file found for FCBAccess"

    if [[ -n "$FRONTBASE_FRAMEWORK" ]]; then
        echo "Will create file at $DIRECTORY/FBCAccess.pc"
        echo "Will sudo"
        sudo tee "$DIRECTORY/FBCAccess.pc" > /dev/null <<END
Name: FBCAccess
Description: Frontbase client library
Version: 1.0
Cflags: -F/Library/Frameworks -I${FRONTBASE_FRAMEWORK}/Versions/Current/Headers
Libs: -F/Library/Frameworks -framework FBCAccess
END
    else
        for DIRECTORY in "${CONFIG_DIRS[@]}"; do
            if [[ -d "$DIRECTORY" ]]; then
                echo "Will create file at $DIRECTORY/FBCAccess.pc"
                echo "Will sudo"
                sudo tee "$DIRECTORY/FBCAccess.pc" > /dev/null <<END
Name: FBCAccess
Description: Frontbase client library
Version: 1.0
Cflags: -I${INCLUDE_DIRECTORY}
Libs: -L${LIBRARY_DIRECTORY} -lFBCAccess
END
                break
            fi
        done
    fi
else
    echo "Found pkgConfig file at $PKG_CONFIG_PATH"
fi

if [[ $OS == "Linux" ]]; then
    if [[ ! -f "/etc/ld.so.conf.d/FrontBase.conf" ]]; then
        echo "Will create file at /etc/ld.so.conf.d/FrontBase.conf"
        echo "Will sudo"
        echo "$LIBRARY_DIRECTORY" | sudo tee "/etc/ld.so.conf.d/FrontBase.conf" > /dev/null
        sudo ldconfig
    fi
fi
