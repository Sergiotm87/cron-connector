.PHONY: build push manifest test verify-codegen charts
TAG?=latest

# docker manifest command will work with Docker CLI 18.03 or newer
# but for now it's still experimental feature so we need to enable that
export DOCKER_CLI_EXPERIMENTAL=enabled

build:
	docker build -t kammin/cron-connector:$(TAG)-amd64 . -f Dockerfile
	docker build --build-arg OPTS="GOARCH=arm64" -t kammin/cron-connector:$(TAG)-arm64 . -f Dockerfile
	docker build --build-arg OPTS="GOARCH=arm GOARM=7" -t kammin/cron-connector:$(TAG)-armhf . -f Dockerfile

push:
	docker push kammin/cron-connector:$(TAG)-amd64
	docker push kammin/cron-connector:$(TAG)-arm64
	docker push kammin/cron-connector:$(TAG)-armhf

manifest:
	docker manifest create --amend kammin/cron-connector:$(TAG) \
		kammin/cron-connector:$(TAG)-amd64 \
		kammin/cron-connector:$(TAG)-arm64 \
		kammin/cron-connector:$(TAG)-armhf
	docker manifest annotate kammin/cron-connector:$(TAG) kammin/cron-connector:$(TAG)-arm64 --os linux --arch arm64
	docker manifest annotate kammin/cron-connector:$(TAG) kammin/cron-connector:$(TAG)-armhf --os linux --arch arm --variant v6
	docker manifest push -p kammin/cron-connector:$(TAG)

test:
	go test ./...

verify-codegen:
	./hack/verify-codegen.sh

charts:
	cd chart && helm package cron-connector/
	mv chart/*.tgz docs/
	helm repo index docs --url https://inlets.github.io/cron-connector/ --merge ./docs/index.yaml

