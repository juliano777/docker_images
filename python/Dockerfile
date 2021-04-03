FROM buildpack-deps:latest AS builder

ARG PKG='libbluetooth-dev tk-dev uuid-dev libssl-dev'


# extra dependencies (over what buildpack-deps already includes)
RUN apt update &&\
	apt install -y --no-install-recommends ${PKG}

ARG PYTHON_VERSION='3.9.3'

ARG PYTHON_URL="https://www.python.org/ftp/python/\
${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"

ARG PYTHONHOME='/usr/local/python'

ENV SHELL '/bin/bash'

# Ensure local python is preferred over distribution python
ENV PATH "${PYTHONHOME}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${PYTHONHOME}/lib:${LD_LIBRARY_PATH}"

ARG CONFIGURE_OPTS="\
		--prefix=${PYTHONHOME} \
		--build=x86_64-linux-gnu \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-loadable-sqlite-extensions \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--with-ssl-default-suites=openssl \
		--without-ensurepip"

ARG PROFILE_TASK="-m test.regrtest --pgo \
		test_array \
		test_base64 \
		test_binascii \
		test_binhex \
		test_binop \
		test_bytes \
		test_c_locale_coercion \
		test_class \
		test_cmath \
		test_codecs \
		test_compile \
		test_complex \
		test_csv \
		test_decimal \
		test_dict \
		test_float \
		test_fstring \
		test_hashlib \
		test_io \
		test_iter \
		test_json \
		test_long \
		test_math \
		test_memoryview \
		test_pickle \
		test_re \
		test_set \
		test_slice \
		test_struct \
		test_threading \
		test_time \
		test_traceback \
		test_unicode"		

# Instalação
RUN set +ex &&\
	export PROFILE_TASK="${PROFILE_TASK}" &&\
	wget -O python.tar.xz ${PYTHON_URL} &&\
	mkdir -p /usr/src/python &&\
	tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz &&\
	rm -frv /usr/local/* python.tar.xz &&\
	cd /usr/src/python &&\	
	./configure ${CONFIGURE_OPTS} &&\
	make -j $((`nproc` + 1)) &&\
	make install &&\
	ldconfig

# pip
RUN wget -O - https://bootstrap.pypa.io/get-pip.py | python3 &&\
	pip install ipython bpython

# Links
RUN	mkdir /usr/local/bin &&\
	cd /usr/local/bin &&\
	ls ${PYTHONHOME}/bin/* | xargs -i ln -s {} &&\
	export PYTHON_VERSION=`echo ${PYTHON_VERSION} | \
		awk -F '.' '{print $1"."$2}'` &&\
	PYBIN=`ls ${PYTHONHOME}/bin/* | egrep "${PYTHON_VERSION}$"` &&\
	for i in ${PYBIN}; do \
		LINK=`echo ${i} |\
			sed "s:${PYTHON_VERSION}\|-::g" |\
			awk -F '/' '{print $(NF)}'`; \
		ln -sf ${i} ${LINK}; \
	done

# Limpeza
RUN find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' + 


# ============================================================================
FROM debian:bullseye-slim AS final

ARG PYTHONHOME='/usr/local/python'
ARG PYTHON_VERSION='3.8'
ARG APT_PKG='sqlite3 libexpat1 libssl1.1 rdfind libncursesw6'
ARG NO_APT='rdfind'

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally 
# breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# Ensure local python is preferred over distribution python
ENV PATH "${PYTHONHOME}/bin:$PATH"
ENV C_INCLUDE_PATH "${PYTHONHOME}/include:${C_INCLUDE_PATH}"
ENV LD_LIBRARY_PATH="${PYTHONHOME}/lib:${LD_LIBRARY_PATH}"
ENV MANPATH "${PYTHONHOME}/share/man:${MANPATH}"

ENV PYTHONPATH "\
.:\
${PYTHONHOME}:\
${PYTHONHOME}/bin:\
${PYTHONHOME}/lib/python${PYTHON_VERSION}:\
${PYTHONHOME}/lib/python${PYTHON_VERSION}/lib-dynload:\
${PYTHONHOME}/lib/python${PYTHON_VERSION}/site-packages"

RUN apt update &&\
	apt install -y ${APT_PKG} &&\
	apt clean &&\
	rdfind -makesymlinks true -outputname /dev/null /usr/local &&\
	ln -s /usr/lib/x86_64-linux-gnu/libffi.so.7.1.0 \
	    /usr/lib/x86_64-linux-gnu/libffi.so.6  &&\
	apt purge -y ${NO_APT} &&\
	rm -fr \
		/var/lib/apt/lists/* \
        /boot \
        /home \
        /media \
        /mnt \
        /usr/local/* \
		/usr/src \
		/var/backups \
		/var/opt \		
		/opt \
        /srv \
		/tmp/*

COPY --from=builder /usr/local /usr/local

CMD 'python'
