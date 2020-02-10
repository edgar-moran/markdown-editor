
[//]: # (title:Gestion des proxy)
[//]: # (style:github)

# Gestion des proxy

## Introduction

Il existe deux type de proxy à la FDJ:

- Le **proxy** dit **utilisateur** qui permet à chacun depuis son PC d'accéder à la quasi totalité d'Internet. De ce fait ce proxy fonctionne:
    - avec une authentification de l'utilisateur (login/password).
    - en mode man-in-the-middle c'est-à-dire qu'il intercepte et filtre toutes les communication (y compris en ssl). Corollaire: en ssl les certificats reçu par le navigateur sont des certificats signés à la volée par l'autorité de certification du proxy.
- Le **proxy** dit **partenaire** qui contrairement au précédent ne nécessite aucune authentification et "n'ouvre" pas la communication ssl. En contre-partie ce proxy a un fonctionnement de type white-list. Il filtre les IP sources et les destination demandées.
 
Dans un cas comme dans l'autre, l'application qui nécessite un proxy doit être capable de savoir quel proxy appeler "en clair" et en "ssl". De plus l'application doit être capable de gérer la liste des ressources demandées qui ne doivent pas être accédées à travers le proxy.
 
En outre dans le premier cas (proxy user) l'application doit en plus être capable de gérer l'authentification au proxy, ainsi que la chaîne de certificats (racine et intermédiaire) de l'autorité de certification particulière à celui-ci.
Ces deux certificats sont disponibles plus bas.
 
Ci-dessous la description de quelques cas pratiques d'utilisation du proxy.

### URLs des proxy
|Nom|URL|
|----|----|
|proxy user|http://proxy.net.fdj.fr:8080|
|proxy partenaire|http://proxypartdmz-vip.prod.fdj.fr:8080|
 
## Proxy système CentOS/RedHat

La gestion des autorités de certification particulières se fait en suivant les étapes suivantes:

1. déposer les fichiers des AC au format **.crt** dans le répertoire **/etc/pki/ca-trust/source/anchors**
2. exécuter la commande de prise en compte des certificats avec le user root (ou à travers sudo): **update-ca-trust**
3. mettre à jour **systemd** avec la commande (toujours sous root ou avec sudo): **systemctl daemon-reload**

La gestion des URL du proxy se fait en renseignant les variables d'environnement suivantes (en majuscule):

- **HTTP_PROXY**: pour indiquer l'url du proxy que l'on veut utiliser pour le traffc HTTP ("en clair")
- **HTTPS_PROXY**: pour indiquer l'url du proxy que l'on veut utiliser pour le trafic HTTPS ("ssl")
- **NO_PROXY**: pour indiquer la liste des URL, domaines, IP, Subnet que l'on souhaite atteindre 
directement (sans passer par un proxy)

Le format de définition des variables HTTP_PROXY et HTTPS_PROXY est le suivant:  
`PROTOCOL://[USERNAME[:PASSWORD]@]HOST[:PORT]`

Exemple si on souhaite utiliser le proxy partenaire:  
`export HTTP_PROXY="http://proxypartdmz-vip.prod.fdj.fr:8080" ; export HTTPS_PROXY="http://proxypartdmz-vip.prod.fdj.fr:8080"`

Le format la variable **NO_PROXY** est une liste de domaine, IP, subnet séparé par une virgule.

Exemple à la FDJ:  
`export NO_PROXY="ojadint,ojadgate,.prod.fdj.fr,.usn.fdj.fr,.dev.fdj.fr,.int.fdj.fr,lx20915,localhost,127.0.0.1,172.26.123.10,10.4.140.56,10.4.140.67,10.4.140.177,10.4.140.183"`
 
Cette configuration standard vaut pour la majorité des applications basées sur libcurl.

## Configuration spécifique: yum

Pour yum (package manager sur CentOS) les variables de définition du proxy sont (en minuscule):

- **http_proxy**
- **https_proxy**
- **no_proxy**

## Proxy système Debian/Ubuntu

Par défaut les systèmes Debian ne disposent pas de l'outil de mise à jour des autorités de certification.  
Il faut tout d'abord l'installer:

`apt-get install -y --no-install-recommends apt-transport-https ca-certificates`

Il ensuite poser les fichiers des AC au format **.crt** dans le répertoire: **/usr/local/share/ca-certificates**  
Et enfin lancer la commande de mise à jour des AC:

`update-ca-certificates`

Pour utiliser le proxy avec le gestionnaire de paquets **apt-get** de Debian il faut éditer le fihcier **/etc/apt/apt.conf** et ajouter les lignes:
```
Acquire::http::Proxy "http://USERNAME:PASSWORD@HOST:PORT";
Acquire::https::Proxy "http://USERNAME:PASSWORD@HOST:PORT";
```

Les variables http_proxy, https_proxy et no_proxy fonctionne aussi.

## Proxy système Alpine

La mise à jour des autorités de certifications fonctionne de la même manière que pour un système Debian.  
Il faut d'abord installer le paquet de gestion des certificats:  

`apk add --no-cache --update ca-certificates`

Puis il faut copier les fichiers des AC au format **.crt** dans le répertoire **/usr/local/share/ca-certificates**.  
Enfin il faut exécuter la commande

`update-ca-certificates`

## Configuration spécifique: apk

Pour apk (package manager sur Alpine), les variables de définition du proxy sont comme suit:

```
export HTTP_PROXY=http://proxyhost:proxyport
export HTTPS_PROXY=http://proxyhost:proxyport
export HTTP_PROXY_AUTH=basic:*:proxyuser:proxypass
```

> /!\ les variables **HTTP_PROXY** et **HTTPS_PROXY** ne __doivent__ pas contenir l'authentification, et la variable **HTTP_PROXY_AUTH** __doit__ être en majuscule !

## Configuration spécifique: curl

Pour bypasser la vérification de la chaîne de certificats il faut utiliser l'option **--insecure**  
Pour utiliser un magasin de certificats contenant les AC il faut préciser l'option: **--cacert FILE**  
Pour l'option précédente, il est également possible d'utiliser la variable d'environnement **CURL_CA_BUNDLE**  
Il est aussi possible de pointer un répertoire contenant une liste de fichiers de certificats d'AC avec l'option: **--capath DIR**  
Pour forcer l'utilisation d'un proxy particulier il y a l'option: **--proxy [PROTOCOL://]HOST[:PORT]**  
Pour préciser l'authentification au proxy: **--proxy-basic --proxy-user USER[:PASSWORD]**  
Pour lister les hosts pour lesquels on ne souhaite pas passer par le proxy: **--noproxy**.

Pour configurer les options de manière globale, il est possible de créer un fichier global de configuration:

- sur unix, ce fichier doit être dans **$CURL_HOME**, **$HOME** ou **~/.** Il doit se nommer .**curlrc**
- sur Windows, il doit être dans **%APPDATA%**. Il doit se nommer  **_curlrc**.

Le format de fichier est comme suit:

```
# this is a comment
cacert = /path/to/certificates.pem
url = "example.com"
output = "curlhere.html"
```

curl utilise également les variables d'environnements suivantes:

- **NO_PROXY**: host-a,host-b,127.0.0.1,host-c
- **ALL_PROXY** [protocol://]<host>[:port]
- **http_proxy** [protocol://]<host>[:port]
- **HTTPS_PROXY** [protocol://]<host>[:port]
- **FTP_PROXY** [protocol://]<host>[:port]
- **FTPS_PROXY** [protocol://]<host>[:port]
- **POP3_PROXY** [protocol://]<host>[:port]
- **IMAP_PROXY** [protocol://]<host>[:port]
- **SMTP_PROXY** [protocol://]<host>[:port]
- **LDAP_PROXY** [protocol://]<host>[:port]

## Configuration spécifique: wget

Pour wget les variables de définition du proxy sont (en minuscule):

- **http_proxy**
- **https_proxy**
- **no_proxy**

Pour bypasser la vérification de la chaîne de certificats il faut utiliser l'option **--no-check-certificate**.  
Pour utiliser un magasin de certificats contenant les AC il faut préciser l'option **--ca-certificate=FILE** (le fichier contient toute la liste des AC au format PEM).  
Il est aussi possible de pointer un répertoire contenant une liste de fichiers de certificats d'AC avec l'option: **--ca-directory=DIR**.  
Pour préciser l'authentification au proxy: **--proxy-user=USER --proxy-password=PASS**.  
Pour désactiver l'utilisation du proxy: **--no-proxy**.  

Pour configurer les options de manière globale, il est possible de créer un fichier global de configuration: **/usr/local/etc/wgetrc** ou **~./.wgetrc**.
 
Le format de fichier est comme suit:

`ca_directory = /usr/local/share/ca-certificates`
 
wget utilise également les variables d'environnements suivantes:

- http_proxy
- https_proxy
- ftp_proxy
- no_proxy

## Configuration spécifique: java

Java a sa propre gestion des certificats.

Ceux-ci sont disponibles dans un keystore: **/etc/pki/java/cacerts**  
Les certificats des AC du proxy doivent être ajoutés dans ce magasin.  
```
keytool -keystore /etc/pki/java/cacerts -importcert -alias ACROOTdeNavigationinternetFDJ -file /etc/pki/ca-trust/source/anchors/ACROOTdeNavigationinternetFDJ.crt
keytool -keystore /etc/pki/java/cacerts -importcert -alias ACproxydeNavigationinternetFDJG2 -file /etc/pki/ca-trust/source/anchors/ACproxydeNavigationinternetFDJG2.crt
```
Le mot de passe par défaut du keystore java est **changeit**.
 
La définition du proxy se fait au démarrage de la JVM en passant des options dans la ligne de commande.
```
-Dhttp.proxyHost=proxypartdmz-vip.prod.fdj.fr
-Dhttp.proxyPort=8080
-Dhttps.proxyHost=proxypartdmz-vip.prod.fdj.fr
-Dhttps.proxyPort=8080
```

## Configuration spécifique: docker

Pour les container docker la configuration du proxy se fait directement dans systemd:

### Configurer le proxy HTTP

**Fichier /etc/systemd/system/docker.service.d/http-proxy.conf**
```
[Service]
Environment="HTTP_PROXY=PROTOCOL://[USERNAME[:PASSWORD]@]HOST[:PORT]" "NO_PROXY=[list]"
```

### Configurer le proxy SSL

**Fichier /etc/systemd/system/docker.service.d/https-proxy.conf**
```
[Service]
Environment="HTTPS_PROXY=PROTOCOL://[USERNAME[:PASSWORD]@]HOST[:PORT]" "NO_PROXY=[list]"
```

## Configuration spécifique: nodeJS

Pour les applications **nodeJS** la configuration du proxy se fait à l'aide de **npm**.  

|Action|Commande|
|----|----|
|Configurer le proxy HTTP|`npm config set proxy PROTOCOL://[USERNAME[:PASSWORD]@]HOST[:PORT]`|
|Configurer le proxy SSL|`npm config set https-proxy PROTOCOL://[USERNAME[:PASSWORD]@]HOST[:PORT]`|
|bypasser la vérification des certificats|`npm config set strict-ssl false`|

Pour supprimer cette configuration

|Action|Commande|
|----|----|
|Supprimer le proxy HTTP|`npm config delete proxy`|
|Supprimer le proxy SSL|`npm config delete https-proxy`|
|Supprimer la gestion des certificats|`npm config delete strict-ssl`|
 
On peut aussi éditer directement le fichier **~/.npmrc**.

## Configuration spécifique: perl

## Configuration spécifique: python (pip)

Pour **pip3** il faut spécifiquement lui indiquer les AC du Proxy (pas de bypass possible).  
Pour cela on crée un fichier contenant toute la liste des AC (root et intermédiaires).

Ex:
```
cat /etc/pki/ca-trust/source/anchors/ACROOTdeNavigationinternetFDJ.crt /etc/pki/ca-trust/source/anchors/ACproxydeNavigationinternetFDJG2.crt > /root/CA.crt
```

Puis on exécute les installations pip3 avec
```
pip3 install --cert /root/CA.crt --disable-pip-version-check --ignore-installed --proxy [user:passwd@]proxy.server:port python-openstackclient
```

## AC du proxy user

### Proxy AC: ACROOTdeNavigationinternetFDJ.crt
```
-----BEGIN CERTIFICATE-----
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
NS8tlp54Ev0H3qy8OHJMo6vhZusBDq8chZQ=
-----END CERTIFICATE-----
```

### Proxy AC: ACproxydeNavigationinternetFDJG2.crt
```
-----BEGIN CERTIFICATE-----
MIIGoDCCBIigAwIBAgIBBzANBgkqhkiG9w0BAQsFADCBsjELMAkGA1UEBhMCRlIx
DzANBgNVBAgTBkZyYW5jZTESMBAGA1UEBxMJVml0cm9sbGVzMR4wHAYDVQQKExVM
YSBGcmFuY2Fpc2UgRGVzIEpldXgxETAPBgNVBAsTCFNFQ09QIFNJMSswKQYDVQQD
EyJBQyBST09UIGRlIE5hdmlnYXRpb24gaW50ZXJuZXQgRkRKMR4wHAYJKoZIhvcN
AQkBFg9zZWNhZG1AbGZkai5jb20wHhcNMTUwODI1MTU0MTIzWhcNMjUwODIyMTU0
MTIzWjCBtzELMAkGA1UEBhMCRlIxDzANBgNVBAgTBkZyYW5jZTESMBAGA1UEBxMJ
Vml0cm9sbGVzMR4wHAYDVQQKExVMYSBGcmFuY2Fpc2UgRGVzIEpldXgxETAPBgNV
BAsTCFNFQ09QIFNJMS8wLQYDVQQDEyZBQyBwcm94eSBkZSBOYXZpZ2F0aW9uIGlu
dGVybmV0IEZESiBHMjEfMB0GCSqGSIb3DQEJARYQc2Vjb3BlckBsZmRqLmNvbTCC
AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANnwBk9m9Ax+/Dcko3OOP3Wz
dgp1ne47eKOE0sIUWx5NPbeEuVTd+Spv+QZl0/L66SyV33a19MMGioPEJ+n3/uSu
3ixPSO4WEBiwAD4wfbka+JYVTxznMg8b/xHDVyfQjfLLIbcnYwpQz4IBjN0u1mv+
LfBhRHJxsJ0wamk2m1HGbVAxm9JSQjvg2i7RZ4BHm1L3goNoJRhU9vO+06uujjIB
rJj21/n6qYe9Atp55e+74pDyB5gk5OWQgAzO1qlpVox8R69qMt4DUtZqOO11WATS
5pwh9wysVdbGThzCWM1i6RBfA4XHniKrDMbkqUjOWXclW4YLkthNrWwCQrJK0aip
hjDR98VmbnPK/Su6dI+AflAk4OhYTQjwSTfYPe53zS9MqAIF5E4hL1QnWDDsS+WP
k5f+eEJqljFBbKlwmVpJ94uJsOiR+bfkQothjJ7x3D1g8MQETfcKZcZc5CL4wovE
RNzcHK3xFX+Q6MVy45uU+Cm0z80THriXFvsuPpSsMexy13OfpGnfVgx1jzVQxTiU
a0L88EzuP5NOV8m0EgbSPyXk1MpmFjEcyHmqQp9QsR21rLTpiktWcJUMUIMMgDFo
+g+dnxz9V2z+ox7lVfjAh03tIRdks8/fqgSTcufBA650LJ2xGgtGM4laBpihV5fh
hVxWSym/4BThG55HQQFnAgMBAAGjgbkwgbYwDAYDVR0TBAUwAwEB/zALBgNVHQ8E
BAMCAQYwWQYJYIZIAYb4QgENBEwWSlRoaXMgY2VydGlmaWNhdGUgaXMgdXNlZCBm
b3IgaXNzdWVpbmcgc3ViLUNBIGNlcnRzIGZvciB0aGUgaW50ZXJuZXQgUHJveHku
MB0GA1UdDgQWBBSowno+eO0lfqvIQbHKzgLwwGA6ITAfBgNVHSMEGDAWgBS7E7tF
munlWGWuu+mpMwZaxEzQvzANBgkqhkiG9w0BAQsFAAOCAgEAaAEaKPFedfToG3Xf
yXfLKW9iD8yfRoJqA788lYt1jxf4bAHInEZQdGhnLr7ffdGmiZLzpvuOwQpBhl/L
keQhtZg2xCxA6rOVswt11TK+zMOIX7LpW9lcKv2wvHKevUaA41kpBPO9yuWVPt5n
bZwHbC+tQVHrWJXiXMzcwIvvln7VA6RcXhr6/N6GKHtHb5siXrRV/qUUDmz+13pH
NQWTh6r6gtCv80JtjcZV+Cbkpn/WU9s7vcbLeBbjmdsl0gt4sAiO+R2Xdu4Ia/5/
DRONbeXF5bLPCUZdyb4R1FuUxV79YiBto/qfyr4zjxfkH52DFxmfJ8nCYfyMyStq
kI+7pCsEXFg1aaXAep0u4G8mXLuohWtVGmIIim4bL/SgDU1lF3T3Ous7ln2sAb4K
aytKq1hirA0tobLK28dbD+DD2FKkSAEJSvHztXIZoV4xLYhQioRs1lsJBcxq07mT
QECnZxE/JtZnkRFjYPCM4u9lqYlpw28SGFI8fy6r6KgQmcjAwo8YknDgkctaIVsX
BVg6iKQJm0xf1dCdAWBwxnJ0jW3pJRg4xKR7Cu6tuEy5IiCO7C/EnxLeGr6xF/xU
nfqvf7oTtLZq9MbA8fXO6LtktJOJrVy5vfdS7CGu9tyJ7Ho+OOCLG58NJ9McWguG
eJwBrWvm8LrUpr1gD+hP2FZlhKo=
-----END CERTIFICATE-----
```

## AC des autorité des certification FDJ d'Intégration

### AC FDJ Root

```
-----BEGIN CERTIFICATE-----
MIIHBTCCBO2gAwIBAgIJANtg+vC/frzGMA0GCSqGSIb3DQEBDAUAMIHZMQswCQYD
VQQGEwJGUjEXMBUGA1UECBMOSGF1dHMgZGUgU2VpbmUxHTAbBgNVBAcTFEJvdWxv
Z25lIEJpbGxhbmNvdXJ0MR4wHAYDVQQKExVMYSBGcmFuY2Fpc2UgRGVzIEpldXgx
FjAUBgNVBAsTDUxGREogU2VjdXJpdHkxOTA3BgNVBAMTMExhIEZyYW5jYWlzZSBE
ZXMgSmV1eCAtIEFDIFJhY2luZSBJbnRlZ3JhdGlvbiBHMjEfMB0GCSqGSIb3DQEJ
ARYQc2Vjb3BlckBsZmRqLmNvbTAeFw0xNzA4MDgxMDIyMDdaFw00NzA4MDExMDIy
MDdaMIHZMQswCQYDVQQGEwJGUjEXMBUGA1UECBMOSGF1dHMgZGUgU2VpbmUxHTAb
BgNVBAcTFEJvdWxvZ25lIEJpbGxhbmNvdXJ0MR4wHAYDVQQKExVMYSBGcmFuY2Fp
c2UgRGVzIEpldXgxFjAUBgNVBAsTDUxGREogU2VjdXJpdHkxOTA3BgNVBAMTMExh
IEZyYW5jYWlzZSBEZXMgSmV1eCAtIEFDIFJhY2luZSBJbnRlZ3JhdGlvbiBHMjEf
MB0GCSqGSIb3DQEJARYQc2Vjb3BlckBsZmRqLmNvbTCCAiIwDQYJKoZIhvcNAQEB
BQADggIPADCCAgoCggIBAM2s+mUaOyzDW0w5pCI5xbUnbqdd2ioYBoK5v6azIs4T
qIDXgqPB1eXYXOS/0+GM/jpesgCoTdo1GqWqv44bMqUznfYbDFuDguJbOpZtjFfc
6fiR/MKbBKYz/NtQAyDsSCDuX5WL0ETJEoDCBnJkp6HtVkjkMJRmMS71fgXH3MYr
7Ad3/Os3Jz81jdn5VAxWGOkLW1sIB14K9zSjAT8E6p36cPt/Qv6051BhUxHLJh1J
FqfMj69IU9Gyq75Zb8VbgrC5037kEnLRFb/1FdVWiMGmnxV3yTTYgFF5E93MR/fx
CJNV1EsE08hRN+E2GGc4+Q5bkJLMWVd1Fepn+3lv7DZDAPa9PffevOg3BtcwEWLk
X5kVeT6AuWJPDOwOsdAK1rLzexsH4pjyk4IvCv/z3H/9hN/2AVaOzOsxF7ChxzPg
SJTJNp2/x0LWYajbG34xeCJ23cOEn7KAWLFwEA3ryUx4GFv48cUTxZcehmYDYkii
vQ1z7okZKYLQagnRtiFi5LODs98E43uY576b0ohgqz5PDw8EF8xO09giXcQzbKTF
VwJbMsP6by+Jm7sk1vTcbCl+5vCY4H0Eak8t2pah07/dUJGWf01AKuUwNK0WeuLS
9wNVZ2RJ2UH9B/T4y+uPY1S9FgLIpMXSmZspGAReiDkRs84+PeBfVcXSLaN39Hnf
AgMBAAGjgc0wgcowDAYDVR0TBAUwAwEB/zALBgNVHQ8EBAMCAQYwRgYDVR0fBD8w
PTA7oDmgN4Y1aHR0cHM6Ly9jZXJ0cy5wcm9kLmZkai5mci9jYS1pbnRlZ3JhdGlv
bi9yb290L2NybC5jcmwwQgYJYIZIAYb4QgENBDUWM1RoaXMgY2VydGlmaWNhdGUg
aXMgdXNlZCBmb3IgaXNzdWVpbmcgc3ViLUNBIGNlcnRzLjAhBglghkgBhvhCAQIE
FBYSQGNydF9yb290X2Jhc2VfdXJsMA0GCSqGSIb3DQEBDAUAA4ICAQCZNXdGlWFT
ZO3LD/f6PfeEPGYxPC77j8LPCIdcMPt2fTrAvIbyxsWIglkNBhIIby0I3X3ehADl
pd98z6jZKx47R2ZAu16baPliebzrF2DkDHQxy1sZvog9Sua0xkAopRwN0kOiBXoy
cLKjRHt5koTJ/4iEbvYaWKX6CW7WYGYBhAitMdGUBPk7R5Ni+6EBZH12hSRjyjYu
Tgf52l2vuPxLm86BXgepAivLoQFk4I6dKun2LtVww0PxvtdUUON6ofCL8ABvFAmg
3IBhf8UZDY1e5jkrbBdt0+Nt6/GPjDjuyj6fRjn/KYKPdXuREElTCgV+9Am+3Wth
9M+JIEdmpxy+kfBq2raFlJmRTw8tps42qW5UI0oBbgwwWqnean08oUJ6Zt+Yk+Q5
pcdS+hutRYWehBRDY03Gq4Qtrw+JT+fe3sp4TKwh5IksRIQZpCuNvjwzPPUAOW8W
AqKaYF43aCeKZ5j9jE1eVYapRZNlPEptVFAnAugETrMhKIRoKmGvWNExqR1vZ6Cw
unveJ0S5zBw0Mf3nj2Jn4P6YKaC37AKuMva6mMJs7hsC+Sq90bIneg9BtatKdpI+
CqH9XfMRjqXbUhuK3umXB7nBI31vb0nw5h3Z5kxccde2NBfsKU2HYqzEjW6jk4qo
5OzDIHpkCgM901p9a9pHYninxrPJ6PLRTg==
-----END CERTIFICATE-----
```

## AC FDJ Server Intermediate

```
-----BEGIN CERTIFICATE-----
MIIF/jCCA+agAwIBAgIBAzANBgkqhkiG9w0BAQsFADCB2TELMAkGA1UEBhMCRlIx
FzAVBgNVBAgTDkhhdXRzIGRlIFNlaW5lMR0wGwYDVQQHExRCb3Vsb2duZSBCaWxs
YW5jb3VydDEeMBwGA1UEChMVTGEgRnJhbmNhaXNlIERlcyBKZXV4MRYwFAYDVQQL
Ew1MRkRKIFNlY3VyaXR5MTkwNwYDVQQDEzBMYSBGcmFuY2Fpc2UgRGVzIEpldXgg
LSBBQyBSYWNpbmUgSW50ZWdyYXRpb24gRzIxHzAdBgkqhkiG9w0BCQEWEHNlY29w
ZXJAbGZkai5jb20wHhcNMTcwODA4MTAyMzQ2WhcNNDcwODAxMTAyMzQ2WjCB2jEL
MAkGA1UEBhMCRlIxFzAVBgNVBAgTDkhhdXRzIGRlIFNlaW5lMR0wGwYDVQQHExRC
b3Vsb2duZSBCaWxsYW5jb3VydDEeMBwGA1UEChMVTGEgRnJhbmNhaXNlIERlcyBK
ZXV4MRYwFAYDVQQLEw1MRkRKIFNlY3VyaXR5MTowOAYDVQQDEzFMYSBGcmFuY2Fp
c2UgRGVzIEpldXggLSBBQyBTZXJ2ZXVyIEludGVncmF0aW9uIEcyMR8wHQYJKoZI
hvcNAQkBFhBzZWNvcGVyQGxmZGouY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEAxlYqG+060FweqKjIyNyqKwmaqrwZJrAh6RKjSrjlVICkvwIUaCqG
PaQ9PGjsPr6MQz/eEyo6CB71asyb8mjnOUrouXKop3COsExg5TYoo/HLrHyxEZ4i
OktTudp081tkYUUrUq6e8KCuX96YcwH4p4J3XGY/dy2mGa+JedRel6P5LeH7hCoS
99NedpN6MiGtCsabdWmBFWkGBmQ6IWAjaJiyMwQd1MaUHcePm1EbkLe3wkh82lPF
Ykqmiu+8aAV+4mehZdDVO1qzwfrd+v1D5ebhs+E0KB0ubReN7kYcsSzOXzlsFjHk
MLUx22gkBOwzMNrEm1c/bCi0siPdgTm2cQIDAQABo4HNMIHKMAwGA1UdEwQFMAMB
Af8wCwYDVR0PBAQDAgEGMEYGA1UdHwQ/MD0wO6A5oDeGNWh0dHBzOi8vY2VydHMu
cHJvZC5mZGouZnIvY2EtaW50ZWdyYXRpb24vcm9vdC9jcmwuY3JsMEIGCWCGSAGG
+EIBDQQ1FjNUaGlzIGNlcnRpZmljYXRlIGlzIHVzZWQgZm9yIGlzc3VlaW5nIHN1
Yi1DQSBjZXJ0cy4wIQYJYIZIAYb4QgECBBQWEkBjcnRfcm9vdF9iYXNlX3VybDAN
BgkqhkiG9w0BAQsFAAOCAgEAVv46jbQPVz9WPPyV2LQbw1IzqkA6+TqGAKEqzesS
U9MaLNo5OZIutdZ50kMpSYPKd8eMuNEn8S/fWNZLP6xsTpUKi19X3g2Th7T1vcFM
Px8QYvhbAHUnYNky1wOrroAlNeW5pV3LgDP8Nka1Fy7aFBfdA3EKG32ouCLRKWNX
WcDyw6aDbOKCRItuEd6FNCVuCQr1c+twWLmgwhJ8ucxy/yGVIcBEUxyWI9fZBSDp
WLHmV15gaQSiLjF9LRWBFSaR6HQxIJiGYLJzcAS8jv9aw0N1pDOuIcr+mBtKGHRn
AD0Wl1ugPUfxTV4bBivNa/0AuruSVAkB5MUpRCG1pbCUqsw5M6yYR6gVPK8Y06/r
uO8svVGRLjiiDPgrUL3tVs8Y/HxLEUdzDpTtvkSfXmVNRZUNpfWGuSyrE6M37dJw
ipgg3WG36dvYTM72p3Y6Qzg6YxkE3tSeEyarBEqoh/h/o27KIubwYBWmVYugfd8+
+l0etDrF6ShvdZ9qlpU7J1cs/gjdfn+nIsM4jnnfELVQO6K6t7Dr9oz+YXTQHoOp
PkQMq/aHsgeinE2N45bG8t0QwHIMAAqEs4zeOVvbI7sTlCpbEl1yEtIsti7k0iNY
pj59ztDSksNg7fe8+ENASmO+uM98zY1aNbxqtG51fpqcT6+rs+ZJ12TNTzPYasS9
dGI=
-----END CERTIFICATE-----
```

## AC FDJ Client Intermediate

```
-----BEGIN CERTIFICATE-----
MIIF/TCCA+WgAwIBAgIBATANBgkqhkiG9w0BAQsFADCB2TELMAkGA1UEBhMCRlIx
FzAVBgNVBAgTDkhhdXRzIGRlIFNlaW5lMR0wGwYDVQQHExRCb3Vsb2duZSBCaWxs
YW5jb3VydDEeMBwGA1UEChMVTGEgRnJhbmNhaXNlIERlcyBKZXV4MRYwFAYDVQQL
Ew1MRkRKIFNlY3VyaXR5MTkwNwYDVQQDEzBMYSBGcmFuY2Fpc2UgRGVzIEpldXgg
LSBBQyBSYWNpbmUgSW50ZWdyYXRpb24gRzIxHzAdBgkqhkiG9w0BCQEWEHNlY29w
ZXJAbGZkai5jb20wHhcNMTcwODA4MTAyMjU0WhcNNDcwODAxMTAyMjU0WjCB2TEL
MAkGA1UEBhMCRlIxFzAVBgNVBAgTDkhhdXRzIGRlIFNlaW5lMR0wGwYDVQQHExRC
b3Vsb2duZSBCaWxsYW5jb3VydDEeMBwGA1UEChMVTGEgRnJhbmNhaXNlIERlcyBK
ZXV4MRYwFAYDVQQLEw1MRkRKIFNlY3VyaXR5MTkwNwYDVQQDEzBMYSBGcmFuY2Fp
c2UgRGVzIEpldXggLSBBQyBDbGllbnQgSW50ZWdyYXRpb24gRzIxHzAdBgkqhkiG
9w0BCQEWEHNlY29wZXJAbGZkai5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
ggEKAoIBAQDGN22Zc29CEov3hbnWxmbcAIpEXU6aShOVEuop3SVzXF9nQ47ez4I0
jl2nEo/OfwlAtqs6DSWZJjjJitH2ON4bFcphi6RJrTrl1sv3CYQTWCkTS+5wVIY+
XE6ZcVY/kH1quqv3c6kRU+MmwizmyaQoRSCRW/vz3vR+1GzGpdj5lqhJ/kw0usYy
Sh8Ke9cdrKM0VbFgl8S1SkNAElrBgWaEGNQNX4dUqLXdyGVSqdv6MgnEx3+V5gkl
2RsXquMRj6p2a3+mn0EBRnopAMGMB2Mi3QckRJyHmek67Y3fSLy0K11TyR/cbYv8
2vCvARe/rktIHIJHnH7LRgGvEzrVbL9DAgMBAAGjgc0wgcowDAYDVR0TBAUwAwEB
/zALBgNVHQ8EBAMCAQYwRgYDVR0fBD8wPTA7oDmgN4Y1aHR0cHM6Ly9jZXJ0cy5w
cm9kLmZkai5mci9jYS1pbnRlZ3JhdGlvbi9yb290L2NybC5jcmwwQgYJYIZIAYb4
QgENBDUWM1RoaXMgY2VydGlmaWNhdGUgaXMgdXNlZCBmb3IgaXNzdWVpbmcgc3Vi
LUNBIGNlcnRzLjAhBglghkgBhvhCAQIEFBYSQGNydF9yb290X2Jhc2VfdXJsMA0G
CSqGSIb3DQEBCwUAA4ICAQATLsFvXcBdvH0W/RHkYHxMBzAqZX81kiI++61Am17m
bD40JumMJ69pkOlun52hSXuLhvu4m3hiwO4OIqZMzmrdYjG7gIh/qsk6KoGSjhZw
tqslsuLXC+W11bTcx4u68npF/bmHZd25YPICfP7T8lQTR3YDUrjVn+cmz2xkqbSn
tgLZx7SHjCFwKt3ablxedFZUv9i1D74aJryYRG/cxRmguUMy7mBPK40oZiJXpqqr
IztWgVxXjv5m2OAleF5fzwMbUfpUcUv8rduuxHXGSk4yT26zDYOqWN9xMbIh9ZCi
7edhJqbt/ljWrGrBqfBDP1EXf5FOpQoK477ByO+S7q0obAztoECGegvv2eRqsr5D
XtW2/tlc3981p6BWCP7dPhtdvaFXLXjfUeC8pr0RlPmWtk8xvVwGXp+6uEPbZ5aQ
a25jfXmUqiJQh6hTKHfQ7iy5s4ztaYQLJAbqOZoKDpRw6yAQJRmGkKVpAwggR+XA
ZTnB+lEYGnvGbaU17noDwxHHowd7c2dsCgMC6//oJsZ6FjB6kBb3uavcN4O8RnCU
E6m84Z7zUDxQLEId4PwLgcv+uPBNIXW827FEliMvRSAsKRo94zeoUEdlB5tRAgaB
EwjkXNRoZSm2Wy+3VsJyepAcgOQVN/L+9xTJUsua3IAT/+RutHSePPOHrB+cYaT1
Qw==
-----END CERTIFICATE-----
```


## AC des autorité des certification FDJ de production

### AC FDJ Root

```
-----BEGIN CERTIFICATE-----
MIIE6zCCA9OgAwIBAgIBADANBgkqhkiG9w0BAQQFADCBvjELMAkGA1UEBhMCRlIx
DzANBgNVBAgTBkZyYW5jZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQx
HjAcBgNVBAoTFUxhIEZyYW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJ
U0VDMSowKAYDVQQDEyFMYSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBSYWNpbmUx
HzAdBgkqhkiG9w0BCQEWEHNlY29wZXJAbGZkai5jb20wHhcNMDUwMTE0MTc0MTUx
WhcNMjUwMTA5MTc0MTUxWjCBvjELMAkGA1UEBhMCRlIxDzANBgNVBAgTBkZyYW5j
ZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQxHjAcBgNVBAoTFUxhIEZy
YW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJU0VDMSowKAYDVQQDEyFM
YSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBSYWNpbmUxHzAdBgkqhkiG9w0BCQEW
EHNlY29wZXJAbGZkai5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
AQC8+4eT7D+4wv0di+7F+37DuWLZaWb59cWF0nHb3lX72MsZosA5ZOIA7OEdWPYb
nDHp9wCH1KqxotJ+LVVaGXUnwcHCWxVHHFC1ccf6j37VTD2Pw4C728o+CqYNRr/3
cLZydF24BNz48O5eZsHuhSVd5kegorIEvO6sBWQ196JJ+S/Gi6WJ7I6lxUkctk1d
FYmqwnmozXdckY+V6R1UF9a699y+JOo1Awor+AwqLRvk7ck4WUm0g6tqBPH1aGeK
KX+AHMhpnYhCg2q3GzT0REJoyuPQ7VwHPEnGSk0EXX9h49ECggWg2mlPU5vWHr0f
SNVE8+i3A+uf1sve7Qol2Sm3AgMBAAGjgfEwge4wDAYDVR0TBAUwAwEB/zALBgNV
HQ8EBAMCAQYwagYDVR0fBGMwYTAuoCygKoYoaHR0cHM6Ly9jZXJ0cy5mZGpldXgu
Y29tL2NhL3Jvb3QvY3JsLmNybDAvoC2gK4YpaHR0cHM6Ly9jZXJ0cy5wcm9kLmZk
ai5mci9jYS9yb290L2NybC5jcmwwQgYJYIZIAYb4QgENBDUWM1RoaXMgY2VydGlm
aWNhdGUgaXMgdXNlZCBmb3IgaXNzdWVpbmcgc3ViLUNBIGNlcnRzLjAhBglghkgB
hvhCAQIEFBYSQGNydF9yb290X2Jhc2VfdXJsMA0GCSqGSIb3DQEBBAUAA4IBAQBr
n/hEzAaDseKRLDmI4T0JqEbsHnb2ka9E2VrBiTOEUryjAMAb7CtZZej/xmwA5Vxj
2a3wGbii3Kr/oALL/AYwwvbZe9Te+/YNhRz219MB3MY9IPYz67ASAnl74y5uWGSy
36sQMYgsnQuwLYo0ebsv4BHIpS8o2h1hNPSaIyRQpsxXrCmLOsNDb/9A/2W/651J
1p+Ec1y8yOiwoGUe2tgBNqyEsQgMkz9uIB5UWoVbe0T/Zp8T42elxJnZGM39r6dm
ltoHT/nva5rpbSOcqO8i/BO8IjG2JTmdqZFXTe6y8tpn345mwL+Rip5ZXWrqtFcs
FGmj0pWrlLFAI5EkjjmO
-----END CERTIFICATE-----
```

## AC FDJ Server Intermediate

```
-----BEGIN CERTIFICATE-----
MIIEaDCCA1CgAwIBAgIBBDANBgkqhkiG9w0BAQUFADCBvjELMAkGA1UEBhMCRlIx
DzANBgNVBAgTBkZyYW5jZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQx
HjAcBgNVBAoTFUxhIEZyYW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJ
U0VDMSowKAYDVQQDEyFMYSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBSYWNpbmUx
HzAdBgkqhkiG9w0BCQEWEHNlY29wZXJAbGZkai5jb20wHhcNMDUwMTE0MTc0NDQ1
WhcNMjUwMTA5MTc0NDQ1WjCBvzELMAkGA1UEBhMCRlIxDzANBgNVBAgTBkZyYW5j
ZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQxHjAcBgNVBAoTFUxhIEZy
YW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJU0VDMSswKQYDVQQDEyJM
YSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBTZXJ2ZXVyMR8wHQYJKoZIhvcNAQkB
FhBzZWNvcGVyQGxmZGouY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDX
DHbocc9uA7R9axJvSdCQNEdO3KXUfcMFLtnRlUoB2ncZO8tBkW6/yh3tTEz1bLkJ
qHjlOm8wdPmsYvEMLOMorM9rsXVcYpBj7dli0kaIyHZDxPRxzvufBWOSjCjDPss0
iJqOnzwrje+dljKiij4oq49Yr3mqrtvaauwU3OPlmwIDAQABo4HxMIHuMAwGA1Ud
EwQFMAMBAf8wCwYDVR0PBAQDAgEGMGoGA1UdHwRjMGEwLqAsoCqGKGh0dHBzOi8v
Y2VydHMuZmRqZXV4LmNvbS9jYS9yb290L2NybC5jcmwwL6AtoCuGKWh0dHBzOi8v
Y2VydHMucHJvZC5mZGouZnIvY2Evcm9vdC9jcmwuY3JsMEIGCWCGSAGG+EIBDQQ1
FjNUaGlzIGNlcnRpZmljYXRlIGlzIHVzZWQgZm9yIGlzc3VlaW5nIHN1Yi1DQSBj
ZXJ0cy4wIQYJYIZIAYb4QgECBBQWEkBjcnRfcm9vdF9iYXNlX3VybDANBgkqhkiG
9w0BAQUFAAOCAQEAZyucy4/cnylkCo8v4RpB8oevFDlxVpU4t+evLlGodq8zIFI5
4mTPnzBTXFyx2WIwdE18R8S4aN/VA7SFPCsteGoDzOpY4P4+CQCWNN0d/dJ7rwRA
8fyP7lJbQat0eBs8m1EVQkN6x/az/HqE4ZNOvebVISO7GUdXE7zxBqc5HcM2JTbc
QsnsS5ZaKmBL5DEm3oL0bVt3mSYoYNO0cfMnuw29LiK33cEATJk6U3y7OB60dwV0
EvZTCW2YD077u7MUWvWBkY+Nd7ophxG85W2CqAz6D9cTgZohFXZe9SqCgVfWyoDc
MuWgfVWiuffqPwVCIHameS6V4pHRckFOQ09vlQ==
-----END CERTIFICATE-----
```

## AC FDJ Client Intermediate

```
-----BEGIN CERTIFICATE-----
MIIEazCCA1OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADCBvjELMAkGA1UEBhMCRlIx
DzANBgNVBAgTBkZyYW5jZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQx
HjAcBgNVBAoTFUxhIEZyYW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJ
U0VDMSowKAYDVQQDEyFMYSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBSYWNpbmUx
HzAdBgkqhkiG9w0BCQEWEHNlY29wZXJAbGZkai5jb20wHhcNMDUwMTE0MTc0MzQz
WhcNMjUwMTA5MTc0MzQzWjCBwjELMAkGA1UEBhMCRlIxDzANBgNVBAgTBkZyYW5j
ZTEdMBsGA1UEBxMUQm91bG9nbmUtQmlsbGFuY291cnQxHjAcBgNVBAoTFUxhIEZy
YW5jYWlzZSBEZXMgSmV1eDESMBAGA1UECxMJTEZESiBJU0VDMS4wLAYDVQQDEyVM
YSBGcmFuY2Fpc2UgRGVzIEpldXggLSBBQyBBdXRoQ2xpZW50MR8wHQYJKoZIhvcN
AQkBFhBzZWNvcGVyQGxmZGouY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQC1+xDeu3wcQT6xOhyOcU/673ZVbk/I+oIsaFxUvKeO811fH0mh5/8obqFJQzwT
t8hewZHbWBR+YK9j2CAWIXpfJTR44DJCYYWATvj9Mf8eebg8sqpuUmDuYkTKli2k
iocNj537gU9syiBrKX+HiulVtv1bSdaRWsmJeL7sLCXwvQIDAQABo4HxMIHuMAwG
A1UdEwQFMAMBAf8wCwYDVR0PBAQDAgEGMGoGA1UdHwRjMGEwLqAsoCqGKGh0dHBz
Oi8vY2VydHMuZmRqZXV4LmNvbS9jYS9yb290L2NybC5jcmwwL6AtoCuGKWh0dHBz
Oi8vY2VydHMucHJvZC5mZGouZnIvY2Evcm9vdC9jcmwuY3JsMEIGCWCGSAGG+EIB
DQQ1FjNUaGlzIGNlcnRpZmljYXRlIGlzIHVzZWQgZm9yIGlzc3VlaW5nIHN1Yi1D
QSBjZXJ0cy4wIQYJYIZIAYb4QgECBBQWEkBjcnRfcm9vdF9iYXNlX3VybDANBgkq
hkiG9w0BAQUFAAOCAQEAktH6YmJc1B3I2S+kM5/Hex8ezVQV4Gy3uCR7pXWG7lvX
92lHOAQUxJROn1S3CwVSvMSxrzLFCbCV8o9wYNudX9eeCL72TPkKNWnOrz1ljHyx
zmUD0wvlAbX5HZYnL1h1YakItpf53dDvPVIeKBnSc7XAqjdARIDVH7JRomJgU9qM
IXEViY6XRogskvxxKVPUekeUypwwLUN6JTu+xS9Z/VbZpR+tL7ou2iPE8HL1DPGW
jlzF0JQRnUFL2z2efn+42T3Eivo6+wzv5XDGtk7brVcXP4AYb1VaFzz7PpmASFQ1
dbwxXojPrsYKXvXIf8Jbc7tQBCLVrVBDHsNExKvBCw==
-----END CERTIFICATE-----
```
