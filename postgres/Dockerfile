# vim:set ft=dockerfile:

# ############################################################################

ARG PYTHON_VERSION='3.7'

FROM python:${PYTHON_VERSION}-slim AS builder

ARG PG_VERSION='12.0'

COPY docker-entrypoint.sh /usr/local/bin/

# ====== Variáveis de Ambiente ===============================================

ENV PKG \
    build-essential bison flex gettext make bzip2 libreadline-dev libssl-dev \
    libxml2-dev libldap2-dev libossp-uuid-dev lbzip2 zlib1g-dev wget locales

ENV PG_SRC postgresql-${PG_VERSION}
ENV PG_SRC_F ${PG_SRC}.tar.bz2
ENV PG_URL https://ftp.postgresql.org/pub/source/v${PG_VERSION}/${PG_SRC_F}

# PostgreSQL

ENV PG_HOME /usr/local/pgsql
ENV PG_BIN ${PG_HOME}/bin
ENV PG_DOC ${PG_HOME}/doc
ENV PG_LIB ${PG_HOME}/lib
ENV PG_MAN ${PG_HOME}/man

ENV PGUSERHOME /var/local/pgsql
ENV PGDATA ${PGUSERHOME}/data
ENV PG_STATS_TEMP ${PGUSERHOME}/pg_stat_tmp
ENV PG_WAL ${PGUSERHOME}/wal
ENV PG_LOG ${PGUSERHOME}/log

ENV PGPORT 5432
ENV PGUSER postgres
ENV PGDATABASE postgres
ENV PGGROUP postgres

# Python

ENV PYTHON /usr/local/bin/python3

ENV LD_LIBRARY_PATH ${PG_LIB}:${LD_LIBRARY_PATH}
ENV PATH ${PG_BIN}:${PATH}
ENV MANPATH ${PG_MAN}:${MANPATH}

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

# Número de jobs conforme a quantidade cores de CPU (cores + 1): 
ENV NJOBS `expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`

# Opções do make
ENV MAKEOPTS -j${NJOBS}

# Tipo de hardware
ENV CHOST x86_64-unknown-linux-gnu

# Flags de otimização para o make 
ENV CFLAGS -O2 -pipe
ENV CXXFLAGS $CFLAGS

# Locales

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
    --auth-local=trust \
    --auth-host=scram-sha-256 \
    -T portuguese \
    -X ${PG_WAL}

# ============================================================================    

RUN apt update
RUN apt install -y ${PKG}
RUN wget -qc ${PG_URL} -P /tmp
RUN tar -xf /tmp/${PG_SRC_F} -C /tmp/

WORKDIR /tmp/${PG_SRC}

# Configuração de idiomas (locales)
RUN localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias \
    pt_BR.UTF-8
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
    en_US.UTF-8
RUN localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
    en_DK.UTF-8

RUN echo '\x auto' > /etc/skel/.psqlrc
RUN echo '\set COMP_KEYWORD_CASE upper' >> /etc/skel/.psqlrc
RUN echo '\set HISTCONTROL ignoreboth' >> /etc/skel/.psqlrc

# ===== Criação de usuário de sistema do PostgreSQL  =====
RUN groupadd ${PGGROUP}
RUN useradd -m -r \
    --shell /bin/bash\
    --gid ${PGGROUP}\
    --home-dir ${PGUSERHOME}\
    --skel /etc/skel\
    --comment 'PostgreSQL System User'\
    ${PGUSER}

# ===== Criação de diretórios e propriedade =====
RUN mkdir -p ${PG_STATS_TEMP} ${PG_WAL} ${PGDATA} ${PG_LOG}
RUN chown -R ${PGUSER}:${PGGROUP} ${PGUSERHOME} 

RUN ./configure ${CONFIGURE_OPTS}
RUN make world
RUN make install-world


# ===== initdb: Criação da instância PostgreSQL  =====
RUN su - postgres -c "${PG_BIN}/initdb ${INITDB_OPTS}"

# ===== Alterações no postgresql.conf =====
RUN sed "s:\(^#listen_addresses.*\):\1\nlisten_addresses = '*':g" \
    -i ${PGDATA}/postgresql.conf
RUN sed "s:\(^#log_destination.*\):\1\nlog_destination = 'stderr':g" \
    -i ${PGDATA}/postgresql.conf
RUN sed "s:\(^#logging_collector.*\):\1\nlogging_collector = on:g" \
    -i ${PGDATA}/postgresql.conf
RUN sed "s:\(^#\)\(log_filename.*\):\1\2\n\2:g" \
    -i ${PGDATA}/postgresql.conf
RUN sed "s:\(^#log_directory.*\):\1\nlog_directory = '${PG_LOG}':g" \
    -i ${PGDATA}/postgresql.conf
RUN sed \
"s:\(^#stats_temp_directory.*\):\1\nstats_temp_directory =\
 '${PG_STATS_TEMP}':g" -i ${PGDATA}/postgresql.conf
RUN sed "s:\(^#password_encryption.*\):\1\npassword_encryption = scram-sha-256:g" \
    -i ${PGDATA}/postgresql.conf 

RUN tar cf /tmp/pg.tar ${PG_HOME} ${PGUSERHOME} /etc \
    /usr/local/bin/docker-entrypoint.sh

# ############################################################################

FROM python:${PYTHON_VERSION}-slim AS final

# ====== Variáveis de Ambiente ===============================================

ENV PKG libldap-2.4-2 libxml2 locales

# PostgreSQL

ENV PG_HOME /usr/local/pgsql
ENV PG_BIN ${PG_HOME}/bin
ENV PG_DOC ${PG_HOME}/doc
ENV PG_LIB ${PG_HOME}/lib
ENV PG_MAN ${PG_HOME}/man

ENV PGUSERHOME /var/local/pgsql
ENV PGDATA ${PGUSERHOME}/data
ENV PG_STATS_TEMP ${PGUSERHOME}/pg_stat_tmp
ENV PG_WAL ${PGUSERHOME}/pg_wal

ENV PGPORT 5432
ENV PGUSER postgres
ENV PGDATABASE postgres


ENV LD_LIBRARY_PATH ${PG_LIB}:${LD_LIBRARY_PATH}
ENV MANPATH ${PG_MAN}:${MANPATH}
ENV PATH ${PG_BIN}:${PATH}

# ============================================================================ 

COPY --from=builder /tmp/pg.tar /tmp/

RUN tar xvf /tmp/pg.tar --overwrite -C / && \
    apt update && \
    apt install -y ${PKG} && \
    apt clean && \
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
        /tmp/* \
        /var/lib/apt/lists/* && \
        localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias \
            pt_BR.UTF-8 &&\
        localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
            en_US.UTF-8 &&\
        localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
            en_DK.UTF-8
     
        
USER ${PGUSER}

WORKDIR ${PGUSERHOME}

EXPOSE ${PGPORT}

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["postgres"]
