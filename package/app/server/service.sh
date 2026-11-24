#!/bin/sh
set -eu
script_dir=/var/packages/dpanel/scripts
. "$script_dir/common"

case "${1:-}" in
    '')
        printf '%s\n' "$serviceUsage"
        exit 0 ;;
    start|stop|restart|status)
        [ "$#" -eq 1 ] || exit 2
        exec /usr/syno/bin/synopkg "$1" dpanel ;;
    server:start) printf '%s\n' "$serviceStart" >&2; exit 2 ;;
esac

# CLI commands must use the same account and config as the DSM service.
[ "$(id -u)" = "$(id -u dpanel)" ] || {
    printf '%s\n' "$maintenanceUser" >&2
    exit 1
}
load_env || { report_error "$invalidEnv"; exit 1; }
cd "$DATA_DIR"
exec "$DPANEL_BIN" "$@"
