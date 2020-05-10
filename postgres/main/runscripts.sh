#!/bin/bash

${1}=\
"${PSQL:-/usr/local/pgsql/bin/psql -U ${PGUSER} -p ${PGPORT} ${PGDATABASE}}"

export PSQL="${1}"

export SCRIPT_DIR='/var/local/pgsql/scripts'

for f in ${SCRIPT_DIR}/*; do

    case "${f}" in
        *.sh)
            if [ -x "${f}" ]; then
                echo "$0: running ${f}"
                "${f}"
            else
                echo "$0: sourcing ${f}"
                . "${f}"
            fi;;

        *.sql)
            echo "$0: running ${f}";
            ${PSQL} -f "${f}";
            echo ;;

        *.sql.bz2)
            echo "$0: running ${f}";
            bzip2 -dc "${f}" | "${PSQL[@]}";
            echo ;;

        *.sql.gz)
            echo "$0: running ${f}";
            gzip -dc "${f}" | "${PSQL[@]}";
            echo ;;

        *.sql.xz)
            echo "$0: running ${f}";
            xz -dc "${f}" | "${PSQL[@]}";
            echo ;;

        *)
            echo "$0: ignoring ${f}" ;;
    esac
echo
