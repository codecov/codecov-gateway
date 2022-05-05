sha := $(shell git rev-parse --short=7 HEAD)
release_version = `cat VERSION`
build_date ?= $(shell git show -s --date=iso8601-strict --pretty=format:%cd $$sha)
branch = $(shell git branch | grep \* | cut -f2 -d' ')
epoch := $(shell date +"%s")
image := us-docker.pkg.dev/genuine-polymer-165712/codecov/enterprise-gateway
dockerhub_image := codecov/enterprise-gateway

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
	DOCKER_BUILDKIT=1 docker build . -t ${image}:latest --build-arg COMMIT_SHA="${sha}" --build-arg VERSION="${release_version}"

build:
	DOCKER_BUILDKIT=1 docker build . -t ${image}:${release_version}-${sha} \
		--label "org.label-schema.build-date"="$(build_date)" \
		--label "org.label-schema.name"="Self-Hosted Gateway" \
		--label "org.label-schema.vendor"="Codecov" \
		--label "org.label-schema.version"="${release_version}-${sha}" \
		--label "org.vcs-branch"="$(branch)" \
		--build-arg COMMIT_SHA="${sha}" \
		--build-arg VERSION="${release_version}" \
		--squash

push:
	docker push ${image}:${release_version}-${sha}
	docker tag ${image}:${release_version}-${sha} ${image}:latest
	docker push ${image}:latest

pull-for-release:
	docker pull ${image}:${release_version}-${sha}

release:
	docker tag ${image}:${release_version}-${sha} ${dockerhub_image}:${release_version}
	docker tag ${image}:${release_version}-${sha} ${dockerhub_image}:latest-stable
	docker push ${dockerhub_image}:${release_version}
	docker push ${dockerhub_image}:latest-stable

dive:
	CI=true dive ${image}:${release_version}-${sha} --lowestEfficiency=0.97 --highestUserWastedPercent=0.06

deep-dive:
	deep-dive --config .deep-dive.yaml ${image}:${release_version}-${sha}