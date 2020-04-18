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

FROM juliano777/postgres AS final

COPY --from=builder /tmp/pg.tar /tmp

RUN tar xvf /tmp/pg.tar -C /

USER "${PGUSER}"
WORKDIR "${PGUSERHOME}"
EXPOSE "${PGPORT}"
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]