# vim:set ft=dockerfile:

# ############################################################################

FROM python:3.8-rc-slim-buster AS builder

COPY docker-entrypoint.sh /usr/local/bin/

# Python

ENV PYTHON_VERSION 3.8
ENV PYTHON /usr/local/bin/python${PYTHON_VERSION}

# Packages

ENV PKG \
    build-essential bison flex gettext make bzip2 libreadline-dev libssl-dev \
    libxml2-dev libldap2-dev libossp-uuid-dev lbzip2 zlib1g-dev wget

# PostgreSQL

ENV PG_MAJOR 12
ENV PG_VERSION 12beta2
ENV PG_SHA256 1738da8e1e59d4f2dc69c216e67100c6d4dad46714cf597cc2db66077204d31f
ENV PG_SRC postgresql-${PG_VERSION}
ENV PG_SRC_F ${PG_SRC}.tar.bz2
ENV PG_URL https://ftp.postgresql.org/pub/source/v${PG_VERSION}/${PG_SRC_F}
ENV PG_HOME /usr/local/pgsql
ENV PG_BIN ${PG_HOME}/bin
ENV PG_DOC ${PG_HOME}/doc
ENV PG_LIB ${PG_HOME}/lib
ENV PG_MAN ${PG_HOME}/man


# Número de jobs conforme a quantidade cores de CPU (cores + 1): 
ENV NJOBS `expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`

# Opções do make
ENV MAKEOPTS -j${NJOBS}

# Tipo de hardware
ENV CHOST x86_64-unknown-linux-gnu

# Flags de otimização para o make 
ENV CFLAGS -O2 -pipe
ENV CXXFLAGS $CFLAGS

ENV CONFIGURE_OPTS \
    --prefix ${PG_HOME} \
    --bindir ${PG_BIN} \
    --with-python \
    --with-libxml \
    --with-openssl \
    --with-ldap \
    --with-uuid=ossp \
    --includedir=/usr/local/include \
    --mandir=${PG_MAN} \
    --docdir=${PG_DOC}

RUN \
    apt update && \
    apt install -y ${PKG} &&\
    wget -c ${PG_URL} -P /tmp && \
    echo 'Verificação do download aqui...' &&\
    tar -xf /tmp/${PG_SRC_F} -C /tmp/ &&\
    cd /tmp/${PG_SRC} &&\
    ./configure ${CONFIGURE_OPTS} &&\
    make world &&\
    make install-world &&\
    tar cvf /tmp/pg.tar ${PG_HOME} /usr/local/bin/docker-entrypoint.sh

# ############################################################################

FROM python:3.8-rc-slim-buster AS final

COPY --from=builder /tmp/pg.tar /tmp/

ENV PG_HOME /usr/local/pgsql
ENV PG_BIN ${PG_HOME}/bin
ENV PG_LIB ${PG_HOME}/lib
ENV PG_MAN ${PG_HOME}/man
ENV PG_LOG /var/log/pgsql

ENV LD_LIBRARY_PATH ${PG_LIB}:${LD_LIBRARY_PATH}
ENV PATH ${PG_BIN}:${PATH}
ENV MANPATH ${PG_MAN}:${MANPATH}
ENV PGPORT 5432
ENV PGDATABASE postgres
ENV PGUSER postgres
ENV PGGROUP postgres
ENV PGUSERHOME /var/local/pgsql
ENV PGDATA ${PGUSERHOME}/data
ENV PG_STATS_TEMP ${PGUSERHOME}/pg_stat_tmp
ENV PG_WAL ${PGUSERHOME}/pg_wal

ENV PKG libldap-2.4-2 libxml2 locales

# Locale

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LOCALE pt_BR.UTF-8
ENV LC_CTYPE pt_BR.UTF-8
ENV LC_NUMERIC en_US.UTF-8
ENV LC_TIME en_DK.UTF-8  # Data no formato YYYY-mm-dd 
ENV LC_COLLATE pt_BR.UTF-8
ENV LC_MONETARY pt_BR.UTF-8
ENV LC_MESSAGES en_US.UTF-8


# initdb

ENV INITDB_OPTS \
    -k \
    -D ${PGDATA} \
    -E utf8 \
    -U ${PGUSER} \
    --locale=${LOCALE} \
    --lc-collate=${LC_COLLATE} \
    --lc-monetary=${LC_MONETARY} \
    --lc-messages=${LC_MESSAGES} \
    -T portuguese \
    -X ${PG_WAL}

ENV LD_LIBRARY_PATH ${PG_LIB}:${LD_LIBRARY_PATH}
ENV MANPATH ${PG_MAN}:${MANPATH}
ENV PATH ${PG_BIN}:${PATH}

RUN \
    printf "\n===== Instalação de pacotes necessários =====\n" &&\
    apt update &&\
    apt install -y ${PKG} &&\
    printf "\n===== Configuração de idiomas (locales) =====\n" &&\
    localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias \
        pt_BR.UTF-8 &&\
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_US.UTF-8 &&\
    localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_DK.UTF-8 &&\
    printf "\n===== Criação de usuário de sistema do PostgreSQL  =====\n" &&\
    echo '\set HISTCONTROL ignoredups' > /etc/skel/.psqlrc &&\
    echo '\set COMP_KEYWORD_CASE upper' >> /etc/skel/.psqlrc &&\
    echo '\x auto' >> /etc/skel/.psqlrc &&\
    groupadd ${PGGROUP} &&\
    useradd -m -r \
        --shell /bin/bash\
        --gid ${PGGROUP}\
        --home-dir ${PGUSERHOME}\
        --skel /etc/skel\
        --comment 'PostgreSQL System User'\
        ${PGUSER} &&\
    printf "\n===== Criação de diretórios e propriedade =====\n" &&\
    mkdir -p ${PG_STATS_TEMP} ${PG_WAL} ${PGDATA} ${PG_LOG} &&\
    chown -R ${PGUSER}:${PGGROUP} \
        ${PG_STATS_TEMP} ${PG_WAL} ${PGDATA} ${PG_LOG} \
        ${PG_CONF} &&\
    printf "\n===== Descompactar a instalação do PostgreSQL  =====\n" &&\
    tar xvf /tmp/pg.tar -C / &&\
    printf "\n===== Remoção de diretórios e arquivos desnecessários =====\n" &&\
    rm -rvf \
        /usr/local/etc\
        /usr/local/games\
        /usr/local/src\
        /boot\
        /home\
        /media\
        /mnt\
        /opt \
        /root \
        /srv \
        /tmp/*\
        /var/lib/apt/lists/* &&\
    cp -rv /etc/skel /root &&\
    printf "\n===== initdb: Criação da instância PostgreSQL  =====\n" &&\
    su - postgres -c "${PG_BIN}/initdb ${INITDB_OPTS}" &&\
    printf "\n===== Alterações no postgresql.conf =====\n" &&\
    sed "s:\(^#listen_addresses.*\):\1\nlisten_addresses = '*':g" \
        -i ${PGDATA}/postgresql.conf &&\
    sed "s:\(^#log_destination.*\):\1\nlog_destination = 'stderr':g" \
        -i ${PGDATA}/postgresql.conf &&\
    sed "s:\(^#logging_collector.*\):\1\nlogging_collector = on:g" \
        -i ${PGDATA}/postgresql.conf &&\
    sed "s:\(^#\)\(log_filename.*\):\1\2\n\2:g" \
        -i ${PGDATA}/postgresql.conf &&\
    sed "s:\(^#log_directory.*\):\1\nlog_directory = '${PG_LOG}':g" \
        -i ${PGDATA}/postgresql.conf &&\
    sed "s:\(^#stats_temp_directory.*\):\1\nstats_temp_directory = '${PG_STATS_TEMP}':g" \
        -i ${PGDATA}/postgresql.conf &&\
    su - postgres -c "echo '\x auto' > ~/.psqlrc" &&\
    su - postgres -c "echo '\set COMP_KEYWORD_CASE upper' >> ~/.psqlrc" &&\
    su - postgres -c "echo '\set HISTCONTROL ignoreboth' >> ~/.psqlrc"
    

USER ${PGUSER}

WORKDIR ${PGUSERHOME}

EXPOSE ${PGPORT}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["postgres"]
