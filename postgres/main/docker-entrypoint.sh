#!/usr/bin/env bash
set -Eeo pipefail
# TODO swap to -Eeuo pipefail above (after handling all potentially-unset
# variables)

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="${1}"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		msg="error: both ${var} and ${fileVar} are set (but are exclusive)"
		echo >&2 "${msg}"
		exit 1
	fi
	local val="${def}"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "${var}"="${val}"
	unset "${fileVar}"
}

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

# print large warning if POSTGRES_PASSWORD is long
# error if both POSTGRES_PASSWORD is empty and POSTGRES_HOST_AUTH_METHOD is not 'trust'
# print large warning if POSTGRES_HOST_AUTH_METHOD is set to 'trust'
# assumes database is not set up, ie: [ -z "$DATABASE_ALREADY_EXISTS" ]
docker_verify_minimum_env() {
	# check password first so we can output the warning before postgres
	# messes it up
	if [ "${#POSTGRES_PASSWORD}" -ge 100 ]; then
		cat >&2 <<-'EOWARN'

			WARNING: The supplied POSTGRES_PASSWORD is 100+ characters.

			  This will not work if used via PGPASSWORD with "psql".

			  https://www.postgresql.org/message-id/flat/E1Rqxp2-0004Qt-PL%40wrigleys.postgresql.org (BUG #6412)
			  https://github.com/docker-library/postgres/issues/507

		EOWARN
	fi	
	
}

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions and permissions
docker_process_init_files() {
	# psql here for backwards compatibility "${psql[@]}"
	psql=( docker_process_sql )

	echo
	local f
	for f; do
		case "${f}" in
			*.sh)
				# https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
				# https://github.com/docker-library/postgres/pull/452
				if [ -x "${f}" ]; then
					echo "$0: running ${f}"
					"${f}"
				else
					echo "${0}: sourcing ${f}"
					. "${f}"
				fi
				;;
			*.sql)     echo "${0}: running ${f}"; docker_process_sql -f "${f}"; echo ;;
			*.sql.bz2) echo "${0}: running ${f}"; bunzip2 -c "${f}" | docker_process_sql; echo ;;
			*.sql.gz)  echo "${0}: running ${f}"; gunzip -c "${f}" | docker_process_sql; echo ;;
			*.sql.xz)  echo "${0}: running ${f}"; xzcat "${f}" | docker_process_sql; echo ;;
			*)         echo "${0}: ignoring ${f}" ;;
		esac
		echo
	done
}

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

	"${query_runner[@]}" "${@}"
}

# create initial database
# uses environment variables for input: POSTGRES_DB
docker_setup_db() {
	if [ "${POSTGRES_DB}" != 'postgres' ]; then
		POSTGRES_DB= docker_process_sql --dbname postgres --set db="${POSTGRES_DB}" <<-'EOSQL'
			CREATE DATABASE :"db" ;
		EOSQL
		echo
	fi
}

# Loads various settings that are used elsewhere in the script
# This should be called before any other functions
docker_setup_env() {
	file_env 'POSTGRES_PASSWORD'
	file_env 'POSTGRES_USER' 'postgres'
	file_env 'POSTGRES_DB' "${POSTGRES_USER}"
	file_env 'POSTGRES_INITDB_ARGS'

	declare -g DATABASE_ALREADY_EXISTS
	# look specifically for PG_VERSION, as it is expected in the DB dir
	if [ -s "${PGDATA}/PG_VERSION" ]; then
		DATABASE_ALREADY_EXISTS='true'
	fi
}

# start socket-only postgresql server for setting up or running scripts
# all arguments will be passed along as arguments to `postgres` (via pg_ctl)
docker_temp_server_start() {
	if [ "${1}" = 'postgres' ]; then
		shift
	fi

	# internal start of server in order to allow setup using psql client
	# does not listen on external TCP/IP and waits until start finishes
	set -- "${@}" -c listen_addresses='' -p "${PGPORT:-5432}"

	PGUSER="${PGUSER:-$POSTGRES_USER}" \
	pg_ctl -D "${PGDATA}" \
		-o "`printf '%q ' "${@}"`" \
		-w start
}

# stop postgresql server after done setting up user and running scripts
docker_temp_server_stop() {
	PGUSER="${PGUSER:-postgres}" \
	pg_ctl -D "${PGDATA}" -m fast -w stop
}

# check arguments for an option that would cause postgres to stop
# return true if there is one
_pg_want_help() {
	local arg
	for arg; do
		case "${arg}" in
			# postgres --help | grep 'then exit'
			# leaving out -C on purpose since it always fails and is unhelpful:
			# postgres: could not access the server configuration file "/var/lib/postgresql/data/postgresql.conf": No such file or directory
			-'?'|--help|--describe-config|-V|--version)
				return 0
				;;
		esac
	done
	return 1
}

_main() {
	# if first arg looks like a flag, assume we want to run postgres server
	if [ "${1:0:1}" = '-' ]; then
		set -- postgres "${@}"
	fi

	if [ "${1}" = 'postgres' ] && ! _pg_want_help "${@}"; then
		docker_setup_env

		# setup data directories and permissions (when run as root)
		if [ "`id -u`" = '0' ]; then
			# then restart script as postgres user
			exec gosu postgres "${BASH_SOURCE}" "${@}"
		fi

		# only run initialization on an empty data directory
		if [ -z "${DATABASE_ALREADY_EXISTS}" ]; then
			docker_verify_minimum_env

			# check dir permissions to reduce likelihood of half-initialized database
			ls ${PGENTRYPOINTDIR} > /dev/null

			# PGPASSWORD is required for psql when authentication is required for 'local' connections via pg_hba.conf and is otherwise harmless
			# e.g. when '--auth=md5' or '--auth-local=md5' is used in POSTGRES_INITDB_ARGS
			export PGPASSWORD="${PGPASSWORD:-$POSTGRES_PASSWORD}"
			docker_temp_server_start "${@}"

			docker_setup_db
			docker_process_init_files ${PGENTRYPOINTDIR}*

			docker_temp_server_stop
			unset PGPASSWORD

			echo
			echo 'PostgreSQL init process complete; ready for start up.'
			echo
		else
			echo
			echo 'PostgreSQL Database directory appears to contain a database; Skipping initialization'
			echo
		fi
	fi

	exec "${@}"
}

if ! _is_sourced; then
	_main "${@}"
fi
