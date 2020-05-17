include make_env

NS ?= jbeley
VERSION ?= latest

IMAGE_NAME ?= viper
CONTAINER_NAME ?= viper
CONTAINER_INSTANCE ?= default
USER=viper
VOLUMES=-v ~/Downloads/:/data:cached -v /tmp:/output:cached -v /mnt2:/malware:cached
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
	docker run --rm  -u viper  -ti --entrypoint /bin/bash ${VOLUMES}  $(NS)/$(IMAGE_NAME):$(VERSION)

shell-root:
	docker run --rm  -u root -ti --entrypoint /bin/bash ${VOLUMES}  $(NS)/$(IMAGE_NAME):$(VERSION)

run:
	docker run  --rm   $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

daemon:
	docker run -d --rm $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

start:
	docker run $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)


stop:
	docker stop $(NS)/$(IMAGE_NAME):$(VERSION)

rm:
	docker rm $(NS)/$(IMAGE_NAME):$(VERSION)

release: build
	make push -e VERSION=$(VERSION)

test: viper

viper:
	docker run -it --rm ${VOLUMES} ${NS}/${IMAGE_NAME}:${VERSION}  /home/viper/.local/bin/viper


default: build
