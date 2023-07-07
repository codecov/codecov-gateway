sha := $(shell git rev-parse --short=7 HEAD)
release_version = `cat VERSION`
build_date ?= $(shell git show -s --date=iso8601-strict --pretty=format:%cd $$sha)
branch = $(shell git branch | grep \* | cut -f2 -d' ')
epoch := $(shell date +"%s")
image := us-docker.pkg.dev/genuine-polymer-165712/codecov/enterprise-gateway
dockerhub_image := codecov/self-hosted-gateway
devops_image := us-docker.pkg.dev/genuine-polymer-165712/codecov-devops/dive:latest
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
	docker build . -t ${image}:${release_version}-latest --build-arg COMMIT_SHA="${sha}" --build-arg VERSION="${release_version}"
	docker tag ${image}:${release_version}-latest ${image}:latest
	docker tag ${image}:${release_version}-latest ${image}:latest-stable

build:
	docker build . -t ${image}:${release_version}-${sha} -t ${image}:${release_version}-latest -t ${dockerhub_image}:rolling \
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
	docker push ${image}:${release_version}-latest

push.rolling:
	docker push ${dockerhub_image}:rolling

pull-for-release:
	docker pull ${image}:${release_version}-${sha}

pull.devops:
	docker pull ${devops_image}

release:
	docker tag ${image}:${release_version}-${sha} ${dockerhub_image}:${release_version}
	docker tag ${image}:${release_version}-${sha} ${dockerhub_image}:latest-stable
	docker tag ${image}:${release_version}-${sha} ${dockerhub_image}:latest-calver
	docker push ${dockerhub_image}:${release_version}
	docker push ${dockerhub_image}:latest-stable
	docker push ${dockerhub_image}:latest-calver

dive:
	$(MAKE) pull.devops
	docker run -e CI=true  -v /var/run/docker.sock:/var/run/docker.sock ${devops_image} dive ${image}:${release_version}-${sha} --lowestEfficiency=0.97 --highestUserWastedPercent=0.06

deep-dive:
	$(MAKE) pull.devops
	docker run -v /var/run/docker.sock:/var/run/docker.sock -v "$(shell pwd)":/tmp ${devops_image} /usr/bin/deep-dive -v --config /tmp/.deep-dive.yaml ${image}:${release_version}-${sha}