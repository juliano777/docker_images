ARG PYTHON_VERSION='3.8'

# ============================================================================

FROM juliano777/python:${PYTHON_VERSION} AS builder

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ARG PG_VERSION='12.2'
ARG PG_SRC="postgresql-${PG_VERSION}"
ARG PG_SRC_F="${PG_SRC}.tar.bz2"
ARG PG_URL="https://ftp.postgresql.org/pub/source/v${PG_VERSION}/${PG_SRC_F}"

ARG PG_HOME='/usr/local/pgsql'
ARG PG_BIN="${PG_HOME}/bin"
ARG PG_DOC="${PG_HOME}/doc"
ARG PG_LIB="${PG_HOME}/lib"
ARG PG_MAN="${PG_HOME}/man"
ARG PGUSERHOME='/var/local/pgsql'
ARG PGDATA="${PGUSERHOME}/data"
ARG PG_STATS_TEMP="${PGUSERHOME}/pg_stat_tmp"
ARG PG_WAL="${PGUSERHOME}/wal"
ARG PG_LOG="${PGUSERHOME}/log"
ARG PGPORT='5432'
ARG PGUSER='postgres'
ARG PGDATABASE='postgres'
ARG PGGROUP='postgres'

# Locales

ARG LANG='en_US.UTF-8'
ARG LANGUAGE='en_US:en'
ARG LOCALE='pt_BR.UTF-8'
ARG LC_CTYPE='pt_BR.UTF-8'
ARG LC_NUMERIC='en_US.UTF-8'

# Data no formato YYYY-mm-dd
ARG LC_TIME='en_DK.UTF-8'

ARG LC_COLLATE='pt_BR.UTF-8'
ARG LC_MONETARY='pt_BR.UTF-8'
ARG LC_MESSAGES='en_US.UTF-8'


ARG PKG="\
    build-essential bison flex gettext make bzip2 libreadline-dev \
    libssl-dev libxml2-dev libldap2-dev libossp-uuid-dev lbzip2 \
    zlib1g-dev wget locales"

ARG CONFIGURE_OPTS="\
    --prefix ${PG_HOME} \
    --bindir ${PG_BIN} \
    --with-python \
    --with-libxml \
    --with-openssl \
    --with-ldap \
    --with-uuid=ossp \
    --includedir=/usr/local/include \
    --mandir=${PG_MAN} \
    --docdir=${PG_DOC}"

# Número de jobs conforme a quantidade cores de CPU (cores + 1): 
ARG NJOBS="`expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`"

# Opções do make
ENV MAKEOPTS="-j${NJOBS}"

# Tipo de hardware
ENV CHOST='x86_64-unknown-linux-gnu'

# Flags de otimização para o make 
ENV CFLAGS='-O2 -pipe'
ENV CXXFLAGS="${CFLAGS}"


# initdb

ARG INITDB_OPTS="\
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
    -X ${PG_WAL}"


ENV PATH="${PG_BIN}:${PATH}"

RUN apt update
RUN apt install -y ${PKG}
RUN wget -O - ${PG_URL} | tar -xjC /tmp/
RUN cd /tmp/${PG_SRC}

RUN echo '\x auto' > /etc/skel/.psqlrc
RUN echo '\set COMP_KEYWORD_CASE upper' >> /etc/skel/.psqlrc
RUN echo '\set HISTCONTROL ignoreboth' >> /etc/skel/.psqlrc

RUN groupadd ${PGGROUP}

RUN useradd -m -r \
    --shell /bin/bash\
    --gid ${PGGROUP}\
    --home-dir ${PGUSERHOME}\
    --skel /etc/skel\
    --comment 'PostgreSQL System User'\
    ${PGUSER}

RUN mkdir -p ${PG_STATS_TEMP} ${PG_WAL} ${PGDATA} ${PG_LOG}
RUN chown -R ${PGUSER}:${PGGROUP} ${PGUSERHOME} 
RUN PYTHON='/usr/local/bin/python' ./configure ${CONFIGURE_OPTS}
RUN make world
RUN make install-world

# Configuração de idiomas (locales)
RUN localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias \
    pt_BR.UTF-8

RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
    en_US.UTF-8

RUN localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
    en_DK.UTF-8

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


RUN pip install --upgrade pip psycopg2 pgcli



RUN tar cf /tmp/pg.tar /usr/local ${PGUSERHOME} /etc \
    /usr/local/bin/docker-entrypoint.sh


# ============================================================================

FROM juliano777/python:${PYTHON_VERSION} AS final

ARG PKG='libldap-2.4-2 libxml2 locales'

COPY --from=builder /tmp/pg.tar /tmp/

RUN apt update &&\
    apt install ${PKG} &&\
    tar xvf /tmp/pg.tar -C /

CMD ['bash']