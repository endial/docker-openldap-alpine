FROM endial/base-alpine:v3.6

MAINTAINER Endial Fang ( endial@126.com )

ENV OPENLDAP_VERSION 2.4.44-r0

RUN  apk update \
  && apk add openldap pwgen \
  && mkdir -p /etc/openldap/schema \
  && rm -rf /var/cache/apk/*

# organisation config
ENV ORGANISATION_NAME "Tidying Lab."
ENV SUFFIX "dc=uac"

# root config
ENV ROOT_USER "admin"

# initial user config
ENV USER_UID "manage"
ENV USER_GIVEN_NAME "Manager"
ENV USER_SURNAME "UAC"
ENV USER_EMAIL "manager@example.com"

# transport layer security configuration
ENV CA_FILE "/srv/cert/openldap/fullchain.pem"
ENV CERT_KEY "/srv/cert/openldap/privkey.pem"
ENV CERT_FILE "/srv/cert/openldap/cert.pem"

# copy modules schemas
COPY schema/* /etc/openldap/schema/

# copy scripts and configuration
COPY scripts/* /etc/openldap/

EXPOSE 389 636

VOLUME ["/srv/conf", "/srv/data"]

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD []
