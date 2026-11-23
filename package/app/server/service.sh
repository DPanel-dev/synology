#!/bin/sh
set -eu

case "${1:-}" in
    '')
        printf '%s\n' 'Usage: service.sh start|stop|restart|status' '       service.sh COMMAND [ARG...]'
        exit 0 ;;
    start|stop|restart|status)
        [ "$#" -eq 1 ] || exit 2
        exec /usr/syno/bin/synopkg "$1" dpanel ;;
    server:start) printf '%s\n' 'Use service.sh start to start the DSM service.' >&2; exit 2 ;;
esac

# CLI commands must use the same account and config as the DSM service.
[ "$(id -u)" = "$(id -u dpanel)" ] || {
    printf '%s\n' 'Run maintenance commands as dpanel (sudo -u dpanel).' >&2
    exit 1
}
. /var/packages/dpanel/scripts/common
load_env || { report_error 'DPanel 的 .env 无效。'; exit 1; }
cd "$DATA_DIR"
exec "$DPANEL_BIN" "$@"
