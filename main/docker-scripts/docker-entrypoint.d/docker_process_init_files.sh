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
					echo "${0}: running ${f}"
					"${f}"
				else
					echo "$0: sourcing ${f}"
					. "${f}"
				fi
				;;

			*.sql)
                echo "$0: running ${f}";
                docker_process_sql -f "${f}";
                echo ;;

			*.sql.gz)
                echo "$0: running ${f}";
                gunzip -c "${f}" | docker_process_sql;
                echo ;;

			*.sql.xz)
                echo "$0: running ${f}";
                xzcat "${f}" | docker_process_sql;
                echo ;;

			*)
                echo "$0: ignoring ${f}" ;;
		esac
		echo
	done
}
