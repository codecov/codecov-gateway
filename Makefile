sha := $(shell git rev-parse --short=7 HEAD)
release_version = `cat VERSION`
build_date ?= $(shell git show -s --date=iso8601-strict --pretty=format:%cd $$sha)
branch = $(shell git branch | grep \* | cut -f2 -d' ')
epoch := $(shell date +"%s")
dockerhub_image := codecov/self-hosted-gateway
IMAGE := ${AR_REPO}
export DOCKER_BUILDKIT := 1

shell:
	docker-compose exec gateway sh
up:
	docker-compose up -d

refresh:
	$(MAKE) build.local
	$(MAKE) up

bootstrap:
	$(MAKE) gcr.auth
	$(MAKE) build.local

gcr.auth:
	gcloud auth configure-docker us-docker.pkg.dev

build.local:
	docker build . -t ${IMAGE}:${release_version}-latest --build-arg COMMIT_SHA="${sha}" --build-arg VERSION="${release_version}"
	docker tag ${IMAGE}:${release_version}-latest ${IMAGE}:latest
	docker tag ${IMAGE}:${release_version}-latest ${IMAGE}:latest-stable

build.self-hosted:
	docker build . -t ${IMAGE}:${release_version}-${sha} -t ${IMAGE}:${release_version}-latest -t ${dockerhub_image}:rolling \
		--label "org.label-schema.build-date"="$(build_date)" \
		--label "org.label-schema.name"="Self-Hosted Gateway" \
		--label "org.label-schema.vendor"="Codecov" \
		--label "org.label-schema.version"="${release_version}-${sha}" \
		--label "org.vcs-branch"="$(branch)" \
		--build-arg COMMIT_SHA="${sha}" \
		--build-arg VERSION="${release_version}"

tag.self-hosted-rolling:
	docker tag ${IMAGE}:${release_version}-${sha} ${dockerhub_image}:rolling

save.self-hosted:
	docker save -o self-hosted.tar ${release_version}-${sha}

load.self-hosted:
	docker load --input self-hosted.tar

push.self-hosted-rolling:
	docker push ${dockerhub_image}:rolling

tag.self-hosted-release:
	docker tag ${IMAGE}:${release_version}-${sha} ${dockerhub_image}:${release_version}
	docker tag ${IMAGE}:${release_version}-${sha} ${dockerhub_image}:latest-stable
	docker tag ${IMAGE}:${release_version}-${sha} ${dockerhub_image}:latest-calver

push.self-hosted-release:
	docker push ${dockerhub_image}:${release_version}
	docker push ${dockerhub_image}:latest-stable
	docker push ${dockerhub_image}:latest-calver