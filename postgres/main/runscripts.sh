#!/bin/bash


function runscripts (){
    PSQL="/usr/local/pgsql/bin/psql -U ${PGUSER} -p ${PGPORT} ${PGDATABASE}" 

    while :
    do
	${PSQL} -l &> /dev/null
        if [ ${?} == 0 ]; then
            echo 'PostgreSQL is ready!'
            break
        fi    

        sleep 3 
    done

    for f in /var/local/pgsql/scripts/*; do

        case "$f" in
            *.sh)
                if [ -x "$f" ]; then
                    echo "$0: running $f"
                    "$f"
                else
                    echo "$0: sourcing $f"
                    . "$f"
                fi;;

            *.sql)
                echo "$0: running $f";
                ${PSQL} -f "$f";
                echo ;;

            *.sql.bz2)
                echo "$0: running $f";
                bzip2 -dc "$f" | "${psql[@]}";
                echo ;;

            *.sql.gz)
                echo "$0: running $f";
                gzip -dc "$f" | "${psql[@]}";
                echo ;;

            *.sql.xz)
                echo "$0: running $f";
                xz -dc "$f" | "${psql[@]}";
                echo ;;

            *)
                echo "$0: ignoring $f" ;;
        esac
    echo

}

pg_ctl start

set +e

runscripts
