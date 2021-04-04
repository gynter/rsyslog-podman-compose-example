#!/usr/bin/env sh
#
# Docker RSyslog local proxy/forwarder example (https://github.com/gynter/rsyslog-docker-example)
#

# Run RSyslog local forwarder in background otherwise we don't have local rsyslogd where to send messages,
/usr/sbin/rsyslogd -n -i /srv/rsyslog/rsyslog.pid &

# Wait a bit before starting to send log messages.
sleep 5

# Send example log message in every few seconds to rsyslogd local forwarder.
i=1
while true; do
  echo "<14>rsyslog-docker-example-local-forwarder-1 entrypoint[$$]: Hello World! #$i" | nc -v -u -w 3 localhost 1514
  i=$(($i+1))
done
