#!/bin/bash

## -------------------------------------------------------------------
##
## Copyright (c) 2012 Basho Technologies, Inc.
##
## This file is provided to you under the Apache License,
## Version 2.0 (the "License"); you may not use this file
## except in compliance with the License.  You may obtain
## a copy of the License at
##
##   http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing,
## software distributed under the License is distributed on an
## "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
## KIND, either express or implied.  See the License for the
## specific language governing permissions and limitations
## under the License.
##
## -------------------------------------------------------------------
##
## Riak Installation Script for installing Riak on Centos & Ubuntu
##
## For more information, visit: https://github.com/basho/riak_on_azure
##
## -------------------------------------------------------------------

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi


logfile=riak_install.log

OS=`lsb_release -si`

echo "Setting limits"
ulimit -n 65536

cat <<PERSISTANTLIMITS > /etc/security/limits.d/riak.conf
root soft nofile 65536
root hard nofile 65536
riak soft nofile 65536
riak hard nofile 65536
PERSISTANTLIMITS

if [ "$OS" = "CentOS" ]; then

echo "Installing Basho Release Repository"
yum -y install http://yum.basho.com/gpg/basho-release-6-1.noarch.rpm >>$logfile 2>&1

echo "Installing Riak"
yum -y install riak >>$logfile 2>&1

elif [ "$OS" = "Ubuntu" ]; then

echo "Installing Basho Release Repository"
curl -s http://apt.basho.com/gpg/basho.apt.key | sudo apt-key add - >>$logfile 2>&1
ubuntuver=`lsb_release -sc`
if ! curl -sf http://apt.basho.com/dists/$ubuntuver/ > /dev/null; then
	ubuntuver='precise'
fi
cat <<BASHOSOURCE >> /etc/apt/sources.list.d/basho.list
deb http://apt.basho.com $ubuntuver main
BASHOSOURCE

apt-get update >>$logfile 2>&1
echo "Installing Riak"
apt-get install riak >>$logfile 2>&1

else
	echo "Unknown OS, this script is for Centos or Ubuntu only"
	exit 1
fi

echo "Configuring /etc/riak/vm.args"
perl -pi -e "s/^-name riak.*$/-sname riak\@`hostname -s`/g" /etc/riak/vm.args

echo "Configuring /etc/riak/app.config"
PASS=`grep -o '<Deployment name="[^"]*"' /var/lib/waagent/SharedConfig.xml | cut -d '"' -f 2`

patch -p0 <<EOF >>$logfile 2>&1
--- /etc/riak/app.config  2014-02-26 22:54:56.706534700 +0000
+++ - 2014-02-26 22:57:06.104057502 +0000
@@ -12,7 +12,7 @@
              
             %% pb is a list of IP addresses and TCP ports that the Riak 
             %% Protocol Buffers interface will bind.
-            {pb, [ {"127.0.0.1", 8087 } ]}
+            {pb, [ {"0.0.0.0", 8087 } ]}
             ]},
 
  %% Riak Core config
@@ -26,18 +26,18 @@
 
               %% http is a list of IP addresses and TCP ports that the Riak
               %% HTTP interface will bind.
-              {http, [ {"127.0.0.1", 8098 } ]},
+              {http, [ {"0.0.0.0", 8098 } ]},
 
               %% https is a list of IP addresses and TCP ports that the Riak
               %% HTTPS interface will bind.
-              %{https, [{ "127.0.0.1", 8098 }]},
+              {https, [{ "0.0.0.0", 8443 }]},
 
               %% Default cert and key locations for https can be overridden
               %% with the ssl config variable, for example:
-              %{ssl, [
-              %       {certfile, "/etc/riak/cert.pem"},
-              %       {keyfile, "/etc/riak/key.pem"}
-              %      ]},
+              {ssl, [
+                     {certfile, "/etc/riak/cert.pem"},
+                     {keyfile, "/etc/riak/key.pem"}
+                    ]},
 
               %% riak_handoff_port is the TCP port that Riak uses for
               %% intra-cluster data handoff.
@@ -324,7 +324,7 @@
  %% riak_control config
  {riak_control, [
                 %% Set to false to disable the admin panel.
-                {enabled, false},
+                {enabled, true},
 
                 %% Authentication style used for access to the admin
                 %% panel. Valid styles are 'userlist' <TODO>.
@@ -333,7 +333,7 @@
                 %% If auth is set to 'userlist' then this is the
                 %% list of usernames and passwords for access to the
                 %% admin panel.
-                {userlist, [{"user", "pass"}
+                {userlist, [{"admin", "%PASSWORD%"}
                            ]},
 
                 %% The admin panel is broken up into multiple
EOF

echo "Generating Certificates"
openssl genrsa -out /etc/riak/key.pem 1024 >>$logfile 2>&1
openssl req -new -key /etc/riak/key.pem -out /etc/riak/csr.pem -subj "/C=/ST=/L=/O=/CN=`hostname`" >>$logfile 2>&1
openssl x509 -req -days 3650 -in /etc/riak/csr.pem -signkey /etc/riak/key.pem -out /etc/riak/cert.pem >>$logfile 2>&1

echo "Tuning system"
cat <<SYSCTL >> /etc/sysctl.conf
vm.swappiness = 0
net.ipv4.tcp_max_syn_backlog = 40000
net.core.somaxconn=4000
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_tw_reuse = 1
SYSCTL

echo 0 > /proc/sys/vm/swappiness
echo 40000 > /proc/sys/net/ipv4/tcp_max_syn_backlog
echo 4000 > /proc/sys/net/core/somaxconn
echo 0 > /proc/sys/net/ipv4/tcp_timestamps
echo 1 > /proc/sys/net/ipv4/tcp_sack
echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
echo 15 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

if [ "$OS" = "CentOS" ]; then

echo "Enabling Service"
chkconfig --add riak >>$logfile 2>&1
echo "Starting Service"
service riak start
service riak ping

elif [ "$OS" = "Ubuntu" ]; then

echo "Starting Service"
service riak start
service riak ping

fi

echo "Riak installation successful"
echo "If any errors occured, check $logfile for more information"
echo "To access Riak Control:"
echo "	1) Create an endpoint with public port of 443, private port of 8069"
echo "	2) In your browser, go to https://<dns>/admin"
echo "		*) username: admin"
echo "		*) password: $PASS"
echo "(The password is the VMs Deployment ID, which can be found on the VMs dashboard)"
