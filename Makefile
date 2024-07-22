sha := $(shell git rev-parse --short=7 HEAD)
release_version = `cat VERSION`
build_date ?= $(shell git show -s --date=iso8601-strict --pretty=format:%cd $$sha)
branch = $(shell git branch | grep \* | cut -f2 -d' ')
epoch := $(shell date +"%s")
AR_REPO ?= codecov/gateway
DOCKERHUB_REPO ?= codecov/self-hosted-gateway
VERSION := ${release_version}-${sha}
export DOCKER_BUILDKIT=1


shell:
	GATEWAY_DOCKER_REPO=${AR_REPO} GATEWAY_DOCKER_VERSION=${VERSION} docker-compose exec gateway sh
up:
	GATEWAY_DOCKER_REPO=${AR_REPO} GATEWAY_DOCKER_VERSION=${VERSION} docker-compose up -d

refresh:
	$(MAKE) build
	$(MAKE) up

build:
	make build.self-hosted

build.local:
	docker build . -t codecov/self-hosted-gateway-dev

build.self-hosted:
	docker build . -t ${AR_REPO}:${VERSION} -t ${AR_REPO}:${release_version}-latest -t ${DOCKERHUB_REPO}:rolling \
		--label "org.label-schema.build-date"="$(build_date)" \
		--label "org.label-schema.name"="Self-Hosted Gateway" \
		--label "org.label-schema.vendor"="Codecov" \
		--label "org.label-schema.version"="${release_version}-${sha}" \
		--label "org.vcs-branch"="$(branch)" \
		--build-arg COMMIT_SHA="${sha}" \
		--build-arg VERSION="${release_version}"


tag.self-hosted-rolling:
	docker tag ${AR_REPO}:${VERSION} ${DOCKERHUB_REPO}:rolling

save.self-hosted:
	docker save -o self-hosted.tar ${AR_REPO}:${VERSION}

load.self-hosted:
	docker load --input self-hosted.tar

push.self-hosted-rolling:
	docker push ${DOCKERHUB_REPO}:rolling

tag.self-hosted-release:
	docker tag ${AR_REPO}:${VERSION} ${DOCKERHUB_REPO}:${release_version}
	docker tag ${AR_REPO}:${VERSION} ${DOCKERHUB_REPO}:latest-stable
	docker tag ${AR_REPO}:${VERSION} ${DOCKERHUB_REPO}:latest-calver

push.self-hosted-release:
	docker push ${DOCKERHUB_REPO}:${release_version}
	docker push ${DOCKERHUB_REPO}:latest-stable
	docker push ${DOCKERHUB_REPO}:latest-calver
