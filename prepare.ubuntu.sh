#!/bin/sh
set -xe
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt -y upgrade

apt install -y --no-install-recommends ssh nsis rpm alien \
  wget cmake pkg-config libglib2.0-dev libssh-dev \
  libhiredis-dev libldap2-dev uuid-dev libksba-dev libsnmp-dev net-tools \
  libgcrypt20-dev libgpgme11-dev bison libpcap-dev doxygen libsqlite3-dev \
  supervisor libgnutls-dev libmicrohttpd-dev libwbxml2-dev g++ sqlite3 \
  libxslt1-dev xsltproc gettext  python-polib rsync gnutls-bin xmltoman \

mkdir -p /etc/redis/
echo "unixsocket /tmp/redis.sock" >> /etc/redis/redis.conf
echo "unixsocketperm 700" >> /etc/redis/redis.conf
echo "daemonize no" >> /etc/redis/redis.conf

cd ~
mkdir source
cd source
wget -q http://wald.intevation.org/frs/download.php/2420/openvas-libraries-9.0.1.tar.gz
wget -q http://wald.intevation.org/frs/download.php/2423/openvas-scanner-5.1.1.tar.gz
wget -q http://wald.intevation.org/frs/download.php/2426/openvas-manager-7.0.1.tar.gz
wget -q http://wald.intevation.org/frs/download.php/2429/greenbone-security-assistant-7.0.2.tar.gz
wget -q http://wald.intevation.org/frs/download.php/2397/openvas-cli-1.4.5.tar.gz
wget -q http://download.redis.io/releases/redis-3.2.8.tar.gz

cd ~/source
tar xf openvas-libraries-9.0.1.tar.gz
cd openvas-libraries-9.0.1
mkdir build
cd build
cmake ..
make
make install

cd ~/source
tar xf openvas-scanner-5.1.1.tar.gz
cd openvas-scanner-5.1.1
mkdir build
cd build
cmake ..
make
make install

cd ~/source
tar xf openvas-manager-7.0.1.tar.gz
cd openvas-manager-7.0.1
mkdir build
cd build
cmake ..
make
make install

cd ~/source
tar xf greenbone-security-assistant-7.0.2.tar.gz
cd greenbone-security-assistant-7.0.2
mkdir build
cd build
cmake  ..
make
make install

cd ~/source
tar xf redis-3.2.8.tar.gz
cd redis-3.2.8
make
make install

cd ~/source
tar xf openvas-cli-1.4.5.tar.gz
cd openvas-cli-1.4.5
mkdir build
cd build
cmake ..
make
make install

ldconfig

cat > /etc/supervisor/conf.d/redis.conf <<- "EOF"
[program:redis]
command=/usr/local/bin/redis-server /etc/redis/redis.conf
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/redis.err.log
stdout_logfile=/var/log/supervisor/redis.out.log
EOF

cat > /etc/supervisor/conf.d/openvassd.conf <<- "EOF"
[program:openvassd]
command=/usr/local/sbin/openvassd -f --unix-socket=/usr/local/var/run/openvassd.sock
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/openvassd.err.log
stdout_logfile=/var/log/supervisor/openvassd.out.log
EOF

cat > /etc/supervisor/conf.d/openvasmd.conf <<- "EOF"
[program:openvasmd]
command=/usr/local/sbin/openvasmd -f -a 0.0.0.0 -p 9390
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/openvasmd.err.log
stdout_logfile=/var/log/supervisor/openvasmd.out.log
EOF

cat > /etc/supervisor/conf.d/gsad.conf <<- "EOF"
[program:gsad]
command=/usr/local/sbin/gsad -f --listen=0.0.0.0 -p 443 --mlisten=127.0.0.1 -m 9390
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/gsad.err.log
stdout_logfile=/var/log/supervisor/gsad.out.log
EOF

cat > /usr/local/bin/init.sh <<- "EOF"
#/bin/sh
openvas-manage-certs -a
## CP gpg
mkdir -p /usr/local/var/lib/openvas/openvasmd/gnupg
cd /usr/local/var/lib/openvas/openvasmd/gnupg
tar xf /var/gnupg.tar.gz
openvasmd --otp-scanner=/usr/local/var/run/openvassd.sock --rebuild
openvasmd --create-user admin --disable-password-policy
openvasmd --user=admin --new-password="OpenVas2017"
EOF

cat > /usr/local/bin/update.all.sh <<- "EOF"
#!/bin/sh
greenbone-certdata-sync --rsync
greenbone-scapdata-sync --rsync
greenbone-nvt-sync --rsync
openvasmd --otp-scanner=/usr/local/var/run/openvassd.sock --update --progress
EOF

cat > /usr/local/bin/entry-point.sh <<- "EOF"
#!/bin/sh
DIR="/usr/local/var/lib/openvas"
if [ ! -e "${DIR}/mgr" ]; then
     /usr/local/bin/init.sh
fi
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
EOF

wget -O /usr/local/bin/openvas-check-setup --no-check-certificate \
  https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup

chmod a+x /usr/local/bin/*
rm -Rf ~/source
