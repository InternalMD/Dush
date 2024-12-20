#!/bin/bash

gl_get_define() {
    impl() (
        # Prepare pattern. Detect numerical values and improve the pattern, so it searches better.
        pattern="$1"
        if grep -qE "^[0-9]+$" <<< "$pattern"; then
            # Decimal constant, convert to hex.
            pattern="$(printf "0x0*%x$\n" "$pattern")"
        elif grep -qE "^0x[0-9A-Za-z]+$" <<< "$pattern"; then
            # Hexadecimal constant, convert all leading zeros to "0*" pattern (e.g. change "0x0001" -> "0x0*1").
            pattern="${pattern#0x}"  # Remove "0x"
            pattern="${pattern##*0}" # Remove leading zeros
            pattern="0x0*$pattern"   # Add "0x0*" prefix
        fi

        # Prepare directories where we will search.
        script_dir="$(dirname "${BASH_SOURCE[0]}")"
        dirs=(
            "$script_dir/opengl_headers/GL"
            "$script_dir/opengl_headers/GLES"
        )

        # Perform the search and postprocessing.
        echo "Searching for pattern \"$pattern\"" >&2
        grep -inr "#define.*$pattern" "${dirs[@]}" |\
            sed -E "s/ +/ /g"                    |\
            sed -E "s/(:[0-9]+):/\1 /g"          |\
            column -t -s' '                      |\
            sort -k2,3                           |\
            uniq -f2                             |\
            sed -E "s/^/    /g"
    )

    if [ -z "$1" ]; then
        # Interactive mode - prompt user for patterns to search.
        while true; do
            echo -n "Specify pattern to search in GL headers: "
            read -r pattern
            if [ -n "$pattern" ]; then
                impl "$pattern"
                echo
            fi
        done
    else
        # Non-interactive mode - pattern is passed from command line.
        impl "$1"
    fi
}
