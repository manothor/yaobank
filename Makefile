# The release version.
VERSION ?= v0.1

# Etcd version. Should match the version in the database/Dockerfile.
ETCD_VERSION ?= v3.3.7

# Constants
PYTHON_VERSION ?= 2.7

.PHONY: calico/yaobank-customer
calico/yaobank-customer:
	docker build -t $@ customer

.PHONY: calico/yaobank-summary
calico/yaobank-summary:
	docker build -t $@ summary

.PHONY: calico/yaobank-database
calico/yaobank-database: database/default.etcd
	# Create a packaged etcd with the populated data (this also modifies group/user settings for this data which is
	# required for OpenShift).
	docker build -t $@ database

database/default.etcd: database/data.txt database/loaddata.py
	# Start an etcd server
	-docker rm -f yaobank-etcd
	docker run --detach \
	  --net=host \
	  --entrypoint=/usr/local/bin/etcd \
	  --name yaobank-etcd quay.io/coreos/etcd:$(ETCD_VERSION) \
	  --advertise-client-urls "http://$(LOCAL_IP_ENV):2379,http://127.0.0.1:2379,http://$(LOCAL_IP_ENV):4001,http://127.0.0.1:4001" \
	  --listen-client-urls "http://0.0.0.0:2379,http://0.0.0.0:4001"
	# Run the python population script
	docker run --net=host -v $(CURDIR)/database:/database python:$(PYTHON_VERSION) sh -c "pip install python-etcd && cd /database && python loaddata.py"
	# Copy out the default.etcd data from the etcd container and delete the etcd container
	docker cp yaobank-etcd:/default.etcd $(CURDIR)/database
	docker rm -f yaobank-etcd

.PHONY: clean
clean:
	-rm -rf database/default.etcd
	-docker rmi calico/yaobank-customer:latest
	-docker rmi calico/yaobank-summary:latest
	-docker rmi calico/yaobank-database:latest
	-docker rmi calico/yaobank-customer:$(VERSION)
	-docker rmi calico/yaobank-summary:$(VERSION)
	-docker rmi calico/yaobank-database:$(VERSION)
	-docker rmi quay.io/calico/yaobank-customer:latest
	-docker rmi quay.io/calico/yaobank-summary:latest
	-docker rmi quay.io/calico/yaobank-database:latest
	-docker rmi quay.io/calico/yaobank-customer:$(VERSION)
	-docker rmi quay.io/calico/yaobank-summary:$(VERSION)
	-docker rmi quay.io/calico/yaobank-database:$(VERSION)

.PHONY: release
release: calico/yaobank-customer calico/yaobank-summary calico/yaobank-database
	docker tag calico/yaobank-customer:latest calico/yaobank-customer:$(VERSION)
	docker tag calico/yaobank-summary:latest calico/yaobank-summary:$(VERSION)
	docker tag calico/yaobank-database:latest calico/yaobank-database:$(VERSION)
	docker tag calico/yaobank-customer:latest quay.io/calico/yaobank-customer:latest
	docker tag calico/yaobank-summary:latest quay.io/calico/yaobank-summary:latest
	docker tag calico/yaobank-database:latest quay.io/calico/yaobank-database:latest
	docker tag calico/yaobank-customer:latest quay.io/calico/yaobank-customer:$(VERSION)
	docker tag calico/yaobank-summary:latest quay.io/calico/yaobank-summary:$(VERSION)
	docker tag calico/yaobank-database:latest quay.io/calico/yaobank-database:$(VERSION)

.PHONY: push
push:
	docker push calico/yaobank-customer:latest
	docker push calico/yaobank-summary:latest
	docker push calico/yaobank-database:latest
	docker push calico/yaobank-customer:$(VERSION)
	docker push calico/yaobank-summary:$(VERSION)
	docker push calico/yaobank-database:$(VERSION)
	docker push quay.io/calico/yaobank-customer:latest
	docker push quay.io/calico/yaobank-summary:latest
	docker push quay.io/calico/yaobank-database:latest
	docker push quay.io/calico/yaobank-customer:$(VERSION)
	docker push quay.io/calico/yaobank-summary:$(VERSION)
	docker push quay.io/calico/yaobank-database:$(VERSION)
