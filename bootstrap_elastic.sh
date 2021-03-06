#!/usr/bin/env bash

apt-get update
mkdir /opt/elastic
chown vagrant:vagrant /opt/elastic
cd /opt/elastic

# Install Oracle JDK 8
add-apt-repository -y ppa:webupd8team/java
apt-get -y -q update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y -q install oracle-java8-installer
update-java-alternatives -s java-8-oracle

# Download the Elastic product tarballs
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$1.tar.gz
wget https://artifacts.elastic.co/downloads/kibana/kibana-$1-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/logstash/logstash-$1.tar.gz
wget https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-$1-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-$1-linux-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$1-linux-x86_64.tar.gz

# Untar the bits
sudo -u vagrant bash -c 'for f in *.tar.gz; do tar xf $f; done'

# Allow all requests to Kibana
cat <<KIBANA_CONF >> /opt/elastic/kibana-$1-linux-x86_64/config/kibana.yml
server.host: "192.168.77.77"
elasticsearch.url: "http://192.168.77.77:9200"
elasticsearch.username: "kibana"
elasticsearch.password: "changeme"
KIBANA_CONF

# Recommended ES settings to pass bootstrap checks
# START BOOTSTRAP CHECKS CONFIG CHANGES #
cat <<ES_CONF >> /opt/elastic/elasticsearch-$1/config/elasticsearch.yml
network.host: 192.168.77.77
path.repo: ["/vagrant/es_snapshots"]
bootstrap.memory_lock: true
discovery.type: single-node
ES_CONF

sed -i -e 's/Xms2g/Xms512m/g' /opt/elastic/elasticsearch-$1/config/jvm.options
sed -i -e 's/Xmx2g/Xmx512m/g' /opt/elastic/elasticsearch-$1/config/jvm.options

sysctl -w vm.max_map_count=262144
cat <<SYSCTL >> /etc/sysctl.conf
vm.max_map_count=262144
SYSCTL

ulimit -n 65536
ulimit -u 2048
ulimit -l unlimited
cat <<SECLIMITS >> /etc/security/limits.conf
*                soft    nofile         1024000
*                hard    nofile         1024000
*                soft    memlock        unlimited
*                hard    memlock        unlimited
vagrant           soft    nofile         1024000
vagrant           hard    nofile         1024000
vagrant           soft    memlock        unlimited
vagrant           hard    memlock        unlimited
vagrant           soft    nproc        2048
vagrant           hard    nproc        2048
vagrant           soft    as        unlimited
vagrant           hard    as        unlimited
root             soft    nofile         1024000
root             hard    nofile         1024000
root             soft    memlock        unlimited
root           soft    as        unlimited
root           hard    as        unlimited
SECLIMITS
# END BOOTSTRAP CHECKS CONFIG CHANGES #

# Install X-Pack in Elasticsearch
cd /opt/elastic/elasticsearch-$1
sudo -u vagrant bash -c 'bin/elasticsearch-plugin install x-pack --batch'
# Run Elasticsearch
sudo -u vagrant nohup bash -c 'bin/elasticsearch' <&- &>/dev/null &

# Install X-Pack in Kibana
cd /opt/elastic/kibana-$1-linux-x86_64
sudo -u vagrant bash -c 'bin/kibana-plugin install x-pack'
# Run Kibana
sudo -u vagrant nohup bash -c 'bin/kibana' <&- &>/dev/null &
