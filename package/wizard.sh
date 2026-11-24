# DSM treats descriptions as HTML inside JSON. Escape only translated text;
# markup and commands in the quoted template must remain literal.
write_wizard() {
    LC_ALL=C awk '
        BEGIN {
            for (i = 1; i < 32; i++) escape[sprintf("%c", i)] = sprintf("\\u%04x", i)
            escape["\\"] = "\\\\"; escape["\""] = "&quot;"
            escape["&"] = "&amp;"; escape["<"] = "&lt;"; escape[">"] = "&gt;"
        }
        {
            line = $0
            while (match(line, /\$\{[A-Za-z][A-Za-z0-9]*\}/)) {
                key = substr(line, RSTART + 2, RLENGTH - 3)
                if (ENVIRON[key] == "") {
                    print "Missing wizard translation: " key > "/dev/stderr"
                    exit 1
                }
                printf "%s", substr(line, 1, RSTART - 1)
                line = substr(line, RSTART + RLENGTH)
                for (i = 1; i <= length(ENVIRON[key]); i++) {
                    c = substr(ENVIRON[key], i, 1)
                    printf "%s", (c in escape ? escape[c] : c)
                }
            }
            print line
        }' > "${SYNOPKG_TEMP_LOGFILE:?}"
}
