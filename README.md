# docker-vas
Docker Image for OpenVAS

Don't know much about OpenVAS, it can run, that's all :)

## Run

~~~bash
#!/bin/sh
docker run --name=openvas-ubuntu \
-p 443:443 \
-p 9390:9390 \
-d \
--restart=always \
-v /var/volume/openvas-ubuntu/data:/usr/local/var/lib/openvas/ \
-v /var/volume/openvas-ubuntu/log:/usr/local/var/log/openvas/ \
-e http_proxy=http://10.211.55.2:8016 \
-e https_proxy=http://10.211.55.2:8016 \
-e RSYNC_PROXY=10.211.55.2:8016 \
dustise/openvas
~~~

## Default login:

- user: `admin`
- password: `OpenVas2017`

## Update Command:

  /usr/local/bin/update.all.sh

## Volumes: /usr/local/var/lib/openvas/

- Database: /usr/local/var/lib/openvas/mgr
- scap data: /usr/local/var/lib/openvas/scap-data
- cert data: /usr/local/var/lib/openvas/cert-data
- plugins: /usr/local/var/lib/openvas/plugins

# Ports:

- 443: Web UI
- 9390: OpenVAS Manager, useful for OpenVAS-cli

# Env Variables (for update):

- http_proxy
- https_proxy
- RSYNC_PROXY
