#!/bin/sh
# docker entrypoint script
# configures and starts LDAP

echo "[i] Start OpenLDAP"

# ensure certificates exist
RETRY=0
MAX_RETRIES=3
until [ -f "$CERT_KEY" ] && [ -f "$CERT_FILE" ] && [ -f "$CA_FILE" ] || [ "$RETRY" -eq "$MAX_RETRIES" ]; do
  RETRY=$((RETRY+1))
  echo "[w] Cannot find certificates. Retry ($RETRY/$MAX_RETRIES) ..."
  sleep 1
done

# exit if no certificates were found after maximum retries
if [ "$RETRY" -eq "$MAX_RETRIES" ]; then
  echo "[i] Cannot start ldap with SSL, the following certificates do not exist"
  echo "[i]  CA_FILE:   $CA_FILE"
  echo "[i]  CERT_KEY:  $CERT_KEY"
  echo "[i]  CERT_FILE: $CERT_FILE"
  echo "[i] Start ldap without SSL ..."
fi

if [ ! -d /srv/data/openldap/openldap-data ]; then
  mkdir -p /srv/data/openldap/openldap-data
  chown ldap:ldap /srv/data/openldap/openldap-data
fi

if [ ! -d /srv/conf/openldap ]; then
  mkdir -p /srv/conf/openldap
fi

if [ ! -f /srv/conf/openldap/slapd.conf ]; then
  cp -rf /etc/openldap/slapd.conf /srv/conf/openldap/
fi

if [ ! -f /srv/conf/openldap/orgnization.ldif ]; then
  cp -rf /etc/openldap/orgnization.ldif /srv/conf/openldap/
fi

if [ ! -f /srv/conf/openldap/users.ldif ]; then
  cp -rf /etc/openldap/users.ldif /srv/conf/openldap/
fi

if [ ! -f /srv/conf/openldap/inited ]; then
  echo "[i] Replace variables in defalut config files"

  # replace variables in slapd.conf
  SLAPD_CONF="/srv/conf/openldap/slapd.conf"

  sed -i "s~%CA_FILE%~$CA_FILE~g" "$SLAPD_CONF"
  sed -i "s~%CERT_KEY%~$CERT_KEY~g" "$SLAPD_CONF"
  sed -i "s~%CERT_FILE%~$CERT_FILE~g" "$SLAPD_CONF"
  sed -i "s~%ROOT_USER%~$ROOT_USER~g" "$SLAPD_CONF"
  sed -i "s~%SUFFIX%~$SUFFIX~g" "$SLAPD_CONF"

  # encrypt root password before replacing
  if [ -z "$ROOT_PW" ]; then
    ROOT_PW=`pwgen -c -n -y -s 64 1`
    touch /srv/conf/openldap/password
    echo "[i] Save root password to /srv/conf/openldap/password"
    echo "Root Password: $ROOT_PW" > /srv/conf/openldap/password
  fi
  ROOT_PW=$(slappasswd -s "$ROOT_PW")
  sed -i "s~%ROOT_PW%~$ROOT_PW~g" "$SLAPD_CONF"

  # replace variables in organisation configuration
  ORG_CONF="/srv/conf/openldap/orgnization.ldif"
  sed -i "s~%SUFFIX%~$SUFFIX~g" "$ORG_CONF"
  sed -i "s~%ORGANISATION_NAME%~$ORGANISATION_NAME~g" "$ORG_CONF"

  # replace variables in user configuration
  USER_CONF="/srv/conf/openldap/users.ldif"
  sed -i "s~%SUFFIX%~$SUFFIX~g" "$USER_CONF"
  sed -i "s~%USER_UID%~$USER_UID~g" "$USER_CONF"
  sed -i "s~%USER_GIVEN_NAME%~$USER_GIVEN_NAME~g" "$USER_CONF"
  sed -i "s~%USER_SURNAME%~$USER_SURNAME~g" "$USER_CONF"
  if [ -z "$USER_PW" ]; then
    USER_PW=`pwgen -c -n -y -s 32 1`
    touch /srv/conf/openldap/password
    echo "[i] Save user password to /srv/conf/openldap/password"
    echo "User UID: $USER_UID" >> /srv/conf/openldap/password
    echo "User Password: $USER_PW" >> /srv/conf/openldap/password
  fi
  sed -i "s~%USER_PW%~$USER_PW~g" "$USER_CONF"
  sed -i "s~%USER_EMAIL%~$USER_EMAIL~g" "$USER_CONF"

  # add organisation and users to ldap (order is important)
  slapadd -l "$ORG_CONF"
  slapadd -l "$USER_CONF"

  touch /srv/conf/openldap/inited 
fi

# add any scripts in ldif
if [ ! -d /srv/conf/openldap/ldif ]; then
  mkdir -p /srv/conf/openldap/ldif
fi

if [ ! -f /srv/conf/openldap/ldif/added ]; then
  echo "[i] Process ldif files in /srv/conf/openldap/ldif"

  for l in /srv/conf/openldap/ldif/*; do
    case "$l" in
      *.ldif)  echo "ENTRYPOINT: adding $l";
            slapadd -l $l
            ;;
      *)      echo "ENTRYPOINT: ignoring $l" ;;
    esac
  done

  touch /srv/conf/openldap/ldif/added
fi

# start ldap, move to CMD in Dockfile
# -f: config file name
# -F: config path
slapd -d stats -u ldap -f /srv/conf/openldap/slapd.conf -g ldap -h "ldap:/// ldaps:///"

# run command passed to docker run
exec "$@"
