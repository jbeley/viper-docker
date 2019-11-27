include make_env

NS ?= jbeley
VERSION ?= latest

IMAGE_NAME ?= viper
CONTAINER_NAME ?= viper
CONTAINER_INSTANCE ?= default
USER=viper
VOLUMES=-v ~/Downloads/:/data:cached -v /tmp:/output:cached
.PHONY: build push shell run start stop rm release

build: Dockerfile
	docker build -t $(NS)/$(IMAGE_NAME):$(VERSION) -f Dockerfile .

hub-build: Dockerfile
	curl -H "Content-Type: application/json" --data '{"build": true}' -X POST ${hub_url}

git-push:
	git commit && \
		git push

push:
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)

shell:
	docker exec -u viper  -ti $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/bash

shell-root:
	docker exec -u root -ti  $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/bash

run:
	docker run  --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

daemon:
	docker run -d --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

start:
	docker run --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)


stop:
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

rm:
	docker rm $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

release: build
	make push -e VERSION=$(VERSION)

test: viper

viper:
	docker run --rm ${VOLUMES} ${NS}/${IMAGE_NAME}  log2timeline.py \
		--artifact_definitions /usr/share/artifacts \
		--data /usr/share/viper \
		--parsers all \
		--partitions all \
		--vss_stores all \
		--hashers md5 \
		--logfile /output/log2timeline/WinXP2.viper.log \
		--status_view none \
		-q  \
		/output/log2timeline/WinXP2.pb /data/WinXP2.E01


default: build
