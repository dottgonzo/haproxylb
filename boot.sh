#/bin/sh

node ./boot.js && cat /usr/local/etc/haproxy/haproxy.cfg && haproxy -d -f /usr/local/etc/haproxy/haproxy.cfg