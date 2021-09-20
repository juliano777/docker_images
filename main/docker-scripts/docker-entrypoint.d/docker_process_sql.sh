# Execute sql script, passed via stdin (or -f flag of pqsl)
# usage: docker_process_sql [psql-cli-args]
#    ie: docker_process_sql --dbname=mydb <<<'INSERT ...'
#    ie: docker_process_sql -f my-file.sql
#    ie: docker_process_sql <my-file.sql
docker_process_sql() {
	local query_runner=( psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --no-password )
	if [ -n "${POSTGRES_DB}" ]; then
		query_runner+=( --dbname "${POSTGRES_DB}" )
	fi

	PGHOST= PGHOSTADDR= "${query_runner[@]}" "${@}"
}
