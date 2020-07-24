FROM juliano777/postgres AS builder

ARG POSTGIS_VERSION='3.0.1'

ARG POSTGIS_URL="https://download.osgeo.org/postgis/source/postgis-\
${POSTGIS_VERSION}.tar.gz"

ARG PKG="\
    wget build-essential pkg-config file libxml2-dev libgeos-dev libproj-dev \
    libprotobuf-c-dev libgdal-dev xsltproc imagemagick protobuf-c-compiler"

USER root

RUN apt update &&\
    apt install -y ${PKG} &&\
    cd /tmp &&\
    wget ${POSTGIS_URL} &&\
    tar xf postgis-${POSTGIS_VERSION}.tar.gz &&\
    cd postgis-${POSTGIS_VERSION} &&\
    ./configure &&\
    make &&\
    make install &&\
    tar cvf /tmp/pg.tar /usr/local/pgsql

# ============================================================================

FROM juliano777/postgres:latest AS final

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

ARG PKG='libgeos-c1v5 libproj19 libjson-c4 libprotobuf-c1 libgdal27 rdfind'

ENV \
    PGDATA="${PGDATA}" \
    PGPORT="${PGPORT}" \
    PGUSER="${PGUSER}" \
    PGDATABASE="${PGDATABASE}" \
    LD_LIBRARY_PATH="${PG_LIB}:${LD_LIBRARY_PATH}" \
    MANPATH="${PG_MAN}:${MANPATH}" \
    PATH="${PG_BIN}:${PATH}" \
    PYTHONPATH="${PYTHONPATH}:${PGPYTHONPATH}"

USER root    

COPY --from=builder /tmp/pg.tar /tmp

RUN \
    apt update &&\
    apt install -y ${PKG} &&\
    apt clean &&\
    tar xvf /tmp/pg.tar --overwrite -C / &&\
    rm -rvf \
        /tmp/* \
        /var/lib/apt/lists/* &&\
    rdfind -makesymlinks true -outputname /dev/null /usr/local
    
USER "${PGUSER}"
WORKDIR "${PGUSERHOME}"
EXPOSE "${PGPORT}"
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
