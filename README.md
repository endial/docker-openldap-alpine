# OpenLDAP Alpine
基于 Alpine 系统的 Docker 镜像，用于提供 OpenLDAP 服务。



## 基本信息

* 镜像地址：endial/openldap-alpine
* 依赖镜像：endial/base-alpine:v3.6




## 数据卷

```
/srv/conf: 用于存放用户的配置文件
/srv/data: 用于存放LDAP数据文件
```



## 使用说明


### LDAP 基本操作

可以使用以下命令搜索LDAP：

```
cp .ldaprc ~
ldapsearch -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com"
```

***注意***：需要按照需要适当修改 `.ldaprc` 文件并拷贝至用户根目录，以使用 TLS 连接 LDAP 服务器。



## 运行参数

Override the following environment variables when running the docker container to customise LDAP:

| VARIABLE          | DESCRIPTION                     | DEFAULT                                  |
| ----------------- | ------------------------------- | ---------------------------------------- |
| ORGANISATION_NAME | Organisation name               | Tidying Lab.                             |
| SUFFIX            | Organisation distinguished name | dc=example,dc=com                        |
| ROOT_USER         | Root username                   | admin                                    |
| ROOT_PW           | Root password                   | password                                 |
| USER_UID          | Initial user's uid              | manage                                   |
| USER_GIVEN_NAME   | Initial user's given name       | Manager                                  |
| USER_SURNAME      | Initial user's surname          | UAC                                      |
| USER_EMAIL        | Initial user's email            | manager@example.com                      |
| USER_PW           | Initial user's password         | password                                 |

For example:

```
docker run --rm --name dvc -d -it \
  endial/dvc-alpine

docker run --volumes-from dvc \
  -p 636:636 \
  -p 389:389 \
  -e ORGANISATION_NAME="Tidying Lab." \
  -e SUFFIX="dc=example,dc=com" \
  -e ROOT_PW="geheimnis" \
  endial/openldap-alpine
```



## 增加 ldif 文件

Copy ldif scripts to /ldif and the container will execute them. This can be done either by extending this Dockerfile with your own:

```
FROM endial/openldap-alpine
COPY my-users.ldif /ldif/
```

Or by mounting your scripts directory into the container:

```
docker run -v /certs:/etc/ssl/certs \
  pgarrett/openssl-alpine

docker run -v /certs:/etc/ssl/certs \
  -p 636:636 \
  -v /my-ldif:/ldif \
  pgarrett/ldap-alpine
```


