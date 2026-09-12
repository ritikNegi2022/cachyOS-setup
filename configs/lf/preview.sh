#!/bin/sh
file="$1"
w="$2"
h="$3"

if [ -d "$file" ]; then
    ls -1A "$file" | head -25 | tr '\n' ' ' | fold -w "$w"
    exit 0
fi

if [ ! -f "$file" ]; then
    exit 1
fi

size=$(du -h "$file" | cut -f1)
mtime=$(stat -c %y "$file" | cut -d. -f1)
ftype=$(file -b --mime-type "$file" 2>/dev/null || echo "unknown")

printf "\033[1m%s (%s, %s)\033[0m\n" "$(basename "$file")" "$size" "$mtime"

case "$ftype" in
    text/*|application/json|application/xml|application/x-shellscript|application/x-python|application/javascript|text/html)
        head -50 "$file" | fold -w "$w" | head -"$h"
        ;;
    image/*)
        if command -v chafa >/dev/null 2>&1; then
            chafa --size="${w}x${h}" "$file" 2>/dev/null
        elif command -v catimg >/dev/null 2>&1; then
            catimg -W "$w" -H "$h" "$file" 2>/dev/null
        else
            printf "Image: %s (%s)\n" "$(basename "$file")" "$size"
        fi
        ;;
    application/pdf)
        printf "PDF: %s (%s)\n" "$(basename "$file")" "$size"
        ;;
    *)
        printf "%s: %s (%s)\n" "$ftype" "$(basename "$file")" "$size"
        ;;
esac
