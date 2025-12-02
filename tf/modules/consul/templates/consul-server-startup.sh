#!/bin/bash
set -e
#exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
if [ -f /var/log/user-data.log ]; then
	echo "userdata_skipped"
	exit 0
fi
exec &> >(tee -a /var/log/user-data.log)
gsutil cp gs://${GCS_BUCKET}/consul.hclic /etc/consul.d/license.hclic
gsutil cp gs://${GCS_BUCKET}/consul-server.hcl /etc/consul.d/consul.hcl
sed -i 's/__DATACENTER__/${DATACENTER}/g' /etc/consul.d/consul.hcl
sed -i 's/__REGION__/${REGION}/g' /etc/consul.d/consul.hcl
systemctl enable consul
systemctl start consul
echo "userdata_done"