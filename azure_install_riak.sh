#!/bin/bash

mkdir /mnt/resource/riak
ln -s /mnt/resource/riak /var/lib/

yum -y install http://s3.amazonaws.com/downloads.basho.com/riak/CURRENT/rhel/6/riak-1.2.1-1.el6.x86_64.rpm

IP=`hostname -i`

perl -pi -e "s/127\.0\.0\.1/$IP/g" /etc/riak/vm.args
perl -pi -e "s/127\.0\.0\.1/$IP/g" /etc/riak/app.config
perl -pi -e 's/\{http, \[/\{http, \[\{\"127.0.0.1\",8098\},/' /etc/riak/app.config


iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8098 -j ACCEPT 
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 6000:7999 -j ACCEPT 
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 4369 -j ACCEPT 
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8099 -j ACCEPT 
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8087 -j ACCEPT

iptables-save > /etc/sysconfig/iptables
service iptables restart

cd /etc/riak

patch -p1 <<EOF
diff -uNr riak.old/app.config riak.new/app.config
--- riak.old/app.config 2012-09-26 10:34:44.454050718 +0000
+++ riak.new/app.config 2012-09-26 10:49:50.171872771 +0000
@@ -1,6 +1,13 @@
 %% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
 %% ex: ft=erlang ts=4 sw=4 et
 [
+ %% Port limitations for firewall configuration.
+ { kernel, 
+           [
+               {inet_dist_listen_min, 6000},
+               {inet_dist_listen_max, 7999}
+           ]},
+
  %% Riak Client APIs config
  {riak_api, [
             %% pb_backlog is the maximum length to which the queue of pending
EOF

chkconfig --add riak
service riak start
service riak ping

#echo "###########################################################"
echo "Riak installation successful"
