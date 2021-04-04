#!/bin/bash

# PostgreSQL installation script

while [ ${#} -gt 0 ]
do
    case ${1} in
        # PostgreSQL version
        '-V' | '--version')
            PG_VERSION=${2};
            shift;;
        
        (--)
            shift;
            break;;

        (-*)
            echo -e "${0} [Error]:\n Unrecognized option ${1}" 1>&2;
            exit 1;;

        (*)
            break;;
    esac
    shift
done

echo ${PG_VERSION}

# Packages to install
PKG="build-essential bison flex gettext make bzip2 libreadline-dev
    libnss-wrapper libssl-dev libxml2-dev libldap2-dev libossp-uuid-dev lbzip2
    zlib1g-dev wget locales"

# Environment variables ======================================================
PG_SRC="postgresql-${PG_VERSION}"
PG_SRC_F="${PG_SRC}.tar.bz2"
PG_URL="https://ftp.postgresql.org/pub/source/v${PG_VERSION}/${PG_SRC_F}"
PG_HOME='/usr/local/pgsql'
PG_BIN="${PG_HOME}/bin"
PG_DOC="${PG_HOME}/doc"
PG_MAN="${PG_HOME}/man"
PGUSERHOME='/var/local/pgsql'
PGPYTHONPATH="${PGUSERHOME}/python"
PGUSER='postgres'
PGGROUP='postgres'
PGPYTHONPATH="${PGUSERHOME}/python"
ARG PG_LOG="${PGUSERHOME}/log"

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

# PATH environment variable
ENV PATH="${PG_BIN}:${PATH}"

# ============================================================================

apt update

apt install -y ${PKG}

wget -qO - ${PG_URL} | tar -xjC /tmp/

cat << EOF > /etc/skel/.psqlrc
\x auto
\set COMP_KEYWORD_CASE upper
\set HISTCONTROL ignoreboth
EOF


groupadd ${PGGROUP}

useradd -m -r \
    --shell /bin/bash\
    --gid ${PGGROUP}\
    --home-dir ${PGUSERHOME}\
    --skel /etc/skel\
    --comment 'PostgreSQL system user'\
    ${PGUSER}
        

    mkdir -p \
        ${PG_STATS_TEMP}\
        ${PGDATA}\
        ${PG_LOG}\
        ${PGPYTHONPATH}
        
        
    chown -R ${PGUSER}:${PGGROUP} ${PGUSERHOME}

    cd /tmp/${PG_SRC}

    PYTHON='/usr/local/bin/python' ./configure ${CONFIGURE_OPTS}

    make world
    
    make install-world