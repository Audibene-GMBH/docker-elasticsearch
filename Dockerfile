FROM openjdk:17-slim-buster
LABEL org.opencontainers.image.authors="pjpires@gmail.com"

# Export HTTP & Transport
EXPOSE 9200 9300

# renovate datasource=github-tags depName=elastic/elasticsearch
ENV ES_VERSION 6.8.22
# renovate datasource=github-tags depName=tianon/gosu
ENV GOSU_VERSION 1.14

ENV DOWNLOAD_URL "https://artifacts.elastic.co/downloads/elasticsearch"
ENV ES_TARBAL "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}.tar.gz"
ENV ES_TARBALL_ASC "${DOWNLOAD_URL}/elasticsearch-${ES_VERSION}.tar.gz.asc"

ENV GOSU_DOWNLOAD_URL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}"
ENV GOSU_GPG_KEY "B42F6819007F00F88E364FD4036A9C25BF357DD4"

COPY elasticsearch-gpg-key /tmp

# Install Elasticsearch.
RUN set -x && apt update && apt install -y bash ca-certificates curl gpg openssl \
  && cd /tmp \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --import /tmp/elasticsearch-gpg-key \
  && gpg --keyserver hkps://keys.openpgp.org --recv-keys "${GOSU_GPG_KEY}" \
  && curl -o elasticsearch.tar.gz -Lskj "$ES_TARBAL" \
  && curl -o elasticsearch.tar.gz.asc -Lskj "$ES_TARBALL_ASC" \
  && gpg --batch --verify elasticsearch.tar.gz.asc elasticsearch.tar.gz \
  && tar -xf elasticsearch.tar.gz \
  && ls -lah \
  && mv elasticsearch-$ES_VERSION /elasticsearch \
  && useradd --no-create-home --shell /sbin/nologin elasticsearch \
  && mkdir -p /elasticsearch/config/scripts /elasticsearch/plugins \
  && chown -R elasticsearch:elasticsearch /elasticsearch \
  && arch=$(dpkg --print-architecture | awk -F- '{ print $NF }') \
  && curl -sLo gosu "${GOSU_DOWNLOAD_URL}/gosu-${arch}" \
  && curl -sLo gosu.asc "${GOSU_DOWNLOAD_URL}/gosu-${arch}.asc" \
  && gpg --batch --verify gosu.asc gosu \
  && chmod +x gosu \
  && mv gosu /usr/local/bin/gosu \
  && rm -rf /tmp/* \
  && apt clean

ENV PATH /elasticsearch/bin:$PATH

WORKDIR /elasticsearch

# Copy configuration
COPY config /elasticsearch/config

# Copy run script
COPY run.sh /

# Set environment variables defaults
ENV ES_JAVA_OPTS "-Xms512m -Xmx512m"
ENV CLUSTER_NAME elasticsearch-default
ENV NODE_MASTER true
ENV NODE_DATA true
ENV NODE_INGEST true
ENV HTTP_ENABLE true
ENV NETWORK_HOST _site_
ENV HTTP_CORS_ENABLE true
ENV HTTP_CORS_ALLOW_ORIGIN *
ENV NUMBER_OF_MASTERS 1
ENV MAX_LOCAL_STORAGE_NODES 1
ENV SHARD_ALLOCATION_AWARENESS ""
ENV SHARD_ALLOCATION_AWARENESS_ATTR ""
ENV MEMORY_LOCK true
ENV REPO_LOCATIONS ""

# Volume for Elasticsearch data
VOLUME ["/data"]

CMD ["/run.sh"]
