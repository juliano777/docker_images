ARG PYTHON_VERSION='3.9'

# ============================================================================

FROM juliano777/python:${PYTHON_VERSION} AS builder

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# PostgreSQL variables
ARG PG_VERSION='13.2'
ARG PG_SRC="postgresql-${PG_VERSION}"
ARG PG_SRC_F="${PG_SRC}.tar.bz2"
ARG PG_URL="https://ftp.postgresql.org/pub/source/v${PG_VERSION}/${PG_SRC_F}"
ARG PG_HOME='/usr/local/pgsql'
ARG PG_BIN="${PG_HOME}/bin"
ARG PG_DOC="${PG_HOME}/doc"
ARG PG_MAN="${PG_HOME}/man"
ARG PGUSERHOME='/var/local/pgsql'
ARG PGDATA="${PGUSERHOME}/data"
ARG PG_STATS_TEMP="${PGUSERHOME}/pg_stat_tmp"
ARG PG_WAL="${PGUSERHOME}/wal"
ARG PG_LOG="${PGUSERHOME}/log"
ARG PGPYTHONPATH="${PGUSERHOME}/python"
ARG PGENTRYPOINTDIR="${PGUSERHOME}/scripts"
ARG PGPORT='5432'
ARG PGUSER='postgres'
ARG PGDATABASE='postgres'
ARG PGGROUP='postgres'

# Locales
ARG LOCALE='pt_BR.UTF-8'
ARG LC_COLLATE='pt_BR.UTF-8'
ARG LC_MONETARY='pt_BR.UTF-8'
ARG LC_MESSAGES='en_US.UTF-8'

# Packages to install
ARG PKG="\
    build-essential bison flex gettext make bzip2 libreadline-dev \
    libssl-dev libxml2-dev libldap2-dev libossp-uuid-dev lbzip2 \
    zlib1g-dev wget locales"

# Configure options to make
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

# Number of jobs according to the number of processor cores +1
ARG NJOBS="`expr \`cat /proc/cpuinfo | egrep ^processor | wc -l\` + 1`"

# Make options
ENV MAKEOPTS="-j${NJOBS}"

# 64 bits
ENV CHOST='x86_64-unknown-linux-gnu'

# Optimization flags to make
ENV CFLAGS='-O2 -pipe'
ENV CXXFLAGS="${CFLAGS}"

# initdb options
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

# PATH environment variable
ENV PATH="${PG_BIN}:${PATH}"

RUN \
    apt update &&\
    apt install -y ${PKG} &&\
    wget -qO - ${PG_URL} | tar -xjC /tmp/ &&\
    echo '\x auto' > /etc/skel/.psqlrc &&\
    echo '\set COMP_KEYWORD_CASE upper' >> /etc/skel/.psqlrc &&\
    echo '\set HISTCONTROL ignoreboth' >> /etc/skel/.psqlrc &&\
    groupadd ${PGGROUP} &&\
    useradd -m -r \
        --shell /bin/bash\
        --gid ${PGGROUP}\
        --home-dir ${PGUSERHOME}\
        --skel /etc/skel\
        --comment 'PostgreSQL System User'\
        ${PGUSER} &&\
    mkdir -p \
        ${PG_STATS_TEMP}\
        ${PG_WAL} \
        ${PGDATA}\
        ${PG_LOG}\
        ${PGPYTHONPATH} \
        ${PGENTRYPOINTDIR} &&\
    chown -R ${PGUSER}:${PGGROUP} ${PGUSERHOME} &&\
    cd /tmp/${PG_SRC} &&\
    PYTHON='/usr/local/bin/python' ./configure ${CONFIGURE_OPTS} &&\
    make world &&\
    make install-world

# Locales
RUN localedef -i `echo ${LOCALE} | cut -f1 -d.` -c -f UTF-8 \
        -A /usr/share/locale/locale.alias "${LOCALE}" &&\
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_US.UTF-8 &&\
    localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_DK.UTF-8

# initdb
RUN su - postgres -c "${PG_BIN}/initdb ${INITDB_OPTS}"

# Overwrite pg_hba.conf
COPY ./pg_hba.conf ${PGDATA}/pg_hba.conf

# Overwrite postgresql.conf
COPY ./postgresql.conf ${PGDATA}/postgresql.conf

# Change owner to postgres user
RUN chown -R ${PGUSER} ${PGDATA}

# Python packages
RUN pip install --upgrade pip psycopg2 pgcli

# tar package
RUN tar cvzf /tmp/pg.tar.gz \
        /usr/local \
        ${PGUSERHOME} \
        /usr/local/bin/docker-entrypoint.sh \
        /etc/passwd \
        /etc/group \
        /etc/shadow \
        /etc/gshadow \
        /etc/skel


# ============================================================================

FROM juliano777/python:${PYTHON_VERSION} AS final

ARG PG_HOME='/usr/local/pgsql'
ARG PG_BIN="${PG_HOME}/bin"
ARG PG_LIB="${PG_HOME}/lib"
ARG PG_MAN="${PG_HOME}/man"
ARG PGUSERHOME='/var/local/pgsql'
ARG PGDATA="${PGUSERHOME}/data"
ARG PGPORT='5432'
ARG PGUSER='postgres'
ARG PGDATABASE='postgres'
ARG PGPYTHONPATH="${PGUSERHOME}/python"
ARG PGENTRYPOINTDIR="${PGUSERHOME}/scripts"

ARG LOCALE='pt_BR.UTF-8'

ARG PKG='bzip2 libldap-2.4-2 libnss-wrapper libxml2 locales rdfind xz-utils'

# Environment Variables

ENV \
    PGDATA="${PGDATA}" \
    PGPORT="${PGPORT}" \
    PGUSER="${PGUSER}" \
    PGDATABASE="${PGDATABASE}" \
    LD_LIBRARY_PATH="${PG_LIB}:${LD_LIBRARY_PATH}" \
    MANPATH="${PG_MAN}:${MANPATH}" \
    PATH="${PG_BIN}:${PATH}" \
    PYTHONPATH="${PYTHONPATH}:${PGPYTHONPATH}" \
    PGENTRYPOINTDIR="${PGENTRYPOINTDIR}"

COPY --from=builder /tmp/pg.tar.gz /tmp/

RUN apt update &&\
    apt install -y ${PKG} &&\
    apt clean && \
    tar xvf /tmp/pg.tar.gz --overwrite -C / &&\
    localedef -i `echo ${LOCALE} | cut -f1 -d.` -c -f UTF-8 \
        -A /usr/share/locale/locale.alias "${LOCALE}" &&\
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_US.UTF-8 &&\
    localedef -i en_DK -c -f UTF-8 -A /usr/share/locale/locale.alias \
        en_DK.UTF-8 &&\
    mkdir /tmp/db-scripts &&\
    rdfind -makesymlinks true -outputname /dev/null /usr/local &&\
    rm -rvf \
        /tmp/* \
        /var/lib/apt/lists/*

USER "${PGUSER}"
WORKDIR "${PGUSERHOME}"
EXPOSE "${PGPORT}"
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]