# Docker RSyslog example (https://github.com/gynter/rsyslog-docker-example)

This example contains two RSyslog Docker containers which gives some insight how to run RSyslog safely and securely
in Docker container.

Example configuration files use RainerScript and basic syntax. Using obsolete syntax is strongly discouraged.

## Container: server

The `server` configuration will start RSyslog server listening on RELP over TLSv1.3. Mutual TLS is used for
authentication and rsyslogd process is executed under unprivileged user as extra security measure.

## Container: local-forwarder

A local forwarder is RSyslog server which acts as a proxy. It listens only on local socket and localhost UDP port 1514
for incoming syslog messages and then forwards those to RSyslog server using RELP protocol over TLSv1.3. The purpose of
local forwarder is that it provides remote logging capabilities if the logger application doesn't support RELP protocol,
which is more reliable than TCP and more secure than UDP. Local forwarder can also be used as a short time data
integrity checking or backup solution in case of RSyslog server failure. That way log messages are still kept in local
forwarder file system for a certain time. It's also possible to use local forwarder as logger mechanism for
applications which don't support syslog logging at all and only log to file system. RSyslog text file input module
(`imfile`) can be used to convert text file to syslog messages and then send those to RSyslog server.

RSyslog process runs under unprivileged user and mTLS is used for client to server communication. Unsecure UDP endpoint
is only exposed to the container itself and cannot be accessed outside of the container.

An example entrypoint shell script is provided which sends log messages to local forwarder in every few seconds.

## Starting containers

To start containers using Docker Compose use the following command:

    # docker-compose up -d

Docker Compose will create volumes for both container working and logs directories.

## Stopping and removing

To stop the containers and remove all volumes which were created by this Docker Compose file, use the following
command:

    # docker-compose down -v

## Accessing the log files

To access the log files for reading one can look for generated log files in Docker volumes directory (default
`/var/lib/docker/volumes/rsyslog-docker-example-server-logs/_data/`) or can execute shell to the container and look
files in directory `/logs` inside the container.

To execute shell in container use the following command:

    # docker exec -it rsyslog-docker-example-server-1 sh

The same method can be used for local forwarder, just replace `rsyslog-docker-example-server` with
`rsyslog-docker-example-local-forwarder` in commands.

## Extending configuration

It's possible to provide Your custom PKI by mounting `/etc/pki/rsyslog` as volume. This also means that it's possible
to overwrite or remove already existing configuration files. It's strongly recommended that those volumes should be
mounted as read-only, `/etc/rsyslog.d` directory can be used to include custom configuration files.

## Important files and directories

- `/etc/rsyslog.conf` - Main rsyslogd configuration file, can be overwritten by a bind mount;
- `/etc/rsyslog.d/` - Extra rsyslogd configuration files, can be mounted as a volume. Files must have `*.conf` extension
  to be loaded by rsyslogd;
- `/srv/rsyslog/` - rsyslogd working directory, PID file will be also created there. It's recommended to mount this
  directory as a volume if there's a need to persist working files (i.e when using queue files to store data on file
  system);
- `/logs/` - A directory for storing log files. Should be mounted as a volume.
- `/tmp/log.sock` - Socket for local system logging;
- `/etc/pki/rsyslog/` - PKI files (CA certificate, server certificate and key) for rsyslogd. Must be mounted as a
   volume or bind mount. File names are defined in `90-remote-log-all.conf` as follows:
     - `ca.pem` - PEM format x509 root or intermediate CA from which TLS certs are issued from;
     - `cert.pem` - PEM format x509 certificate for client for mTLS;
     - `key.pem` - Private key corresponding to server certificate.

## Environment variables

- `RSYSLOG_RELP_TARGET` - RSyslog server hostname or IP address;
- `RSYSLOG_RELP_TARGET_PORT` - RSyslog server port;
- `RSYSLOG_TLS_PERMITTED_PEER` - List of permitted peer's as defined in [TLS.PermittedPeer](https://www.rsyslog.com/doc/v8-stable/configuration/modules/imrelp.html#tls-permittedpeer).
  Domain names must correspond to x509 certificate SAN extension DNS Name value.

## Known issues

It's not possible to use list format `["peer1_name", "peer2_name"]` for `RSYSLOG_TLS_PERMITTED_PEER`. It might be
due to rsyslogd-s failure to expand environment variables correctly if those contain special characters. This needs
further analysis.

## License

Parts of RSyslog official documentation were used in configuration file comments, therefore the license is same as
RSyslog documentation, Apache License Version 2.0. The copy of the license can be found in file `LICENSE`.
