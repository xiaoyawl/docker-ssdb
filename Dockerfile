FROM benyoo/alpine:3.4.20160812

MAINTAINER from www.dwhd.org by lookback (mondeolove@gmail.com)
ARG VERSION=${VERSION:-1.9.2}
ENV TMP_DIR=/tmp/ssdb \
	DATA_DIR=/data/ssdb


RUN set -x && \
	LOCAL_MIRRORS=${LOCAL_MIRRORS:-http://mirrors.ds.com/alpine} && \
	NET_MIRRORS=${NET_MIRRORS:-http://dl-cdn.alpinelinux.org/alpine} && \
	LOCAL_MIRRORS_HTTP_CODE=$(curl -LI -m 10 -o /dev/null -sw %{http_code} ${LOCAL_MIRRORS}) && \
	if [ "${LOCAL_MIRRORS_HTTP_CODE}" == "200" ]; then \
		echo -e "${LOCAL_MIRRORS}/v3.4/main\n${LOCAL_MIRRORS}/v3.4/community" > /etc/apk/repositories; else \
		echo -e "${NET_MIRRORS}/v3.4/main\n${NET_MIRRORS}/v3.4/community" > /etc/apk/repositories; fi && \
	mkdir -p ${TMP_DIR} ${DATA_DIR} && \
	apk --update --no-cache upgrade && \
	apk add --no-cache --virtual .build-deps \
		gcc g++ make autoconf libc-dev libevent-dev linux-headers perl tar && \
	curl -Lk "https://github.com/ideawu/ssdb/archive/${VERSION}.tar.gz" | tar -xz -C ${TMP_DIR} --strip-components=1 && \
	cd ${TMP_DIR} && \
	make -j$(getconf _NPROCESSORS_ONLN) && \
	make install && \
	cp ssdb.conf /etc && \
	cp ssdb-server /usr/bin && \
	#mkdir -p /var/lib/ssdb && \
	sed -e "s@home.*@home $(dirname $DATA_DIR)@" -e "s/loglevel.*/loglevel info/" -e "s@work_dir = .*@work_dir = ${DATA_DIR}@" \
		-e "s@pidfile = .*@pidfile = /run/ssdb.pid@" -e "s@level:.*@level: info@" -e "s@ip:.*@ip: 0.0.0.0@" -i /etc/ssdb.conf && \
	apk del .build-deps && \
	apk add --virtual .ssdb-rundeps libstdc++ && \
	rm -rf ${TMP_DIR} /var/cache/apk

EXPOSE 8888
VOLUME ${DATA_DIR}
ENTRYPOINT /usr/bin/ssdb-server /etc/ssdb.conf
