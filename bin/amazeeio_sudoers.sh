#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run with elevated permissions (sudo)"
  exit
fi

if [ ! -d "$DIRECTORY" ]; then
  mkdir -p /private/etc/sudoers.d
fi

cat > /private/etc/sudoers.d/amazeeio << EOF
Cmnd_Alias AMAZEEIO_NFS = /usr/local/Cellar/cachalot/0.11.1/bin/amazeeio-cachalot nfs *
Cmnd_Alias AMAZEEIO_RESOLVER = /bin/rm -f /etc/resolver/docker.amazee.io
Cmnd_Alias AMAZEEIO_MDNS = /usr/bin/killall mDNSResponder
Cmnd_Alias AMAZEEIO_RESOLVER_UP = /bin/cp * /etc/resolver/docker.amazee.io
Cmnd_Alias AMAZEEIO_RESOLVER_CHMOD = /bin/chmod 644 /etc/resolver/docker.amazee.io
%admin ALL=(root) NOPASSWD: AMAZEEIO_NFS, AMAZEEIO_RESOLVER, AMAZEEIO_MDNS, AMAZEEIO_RESOLVER_UP, AMAZEEIO_RESOLVER_CHMOD

EOF
