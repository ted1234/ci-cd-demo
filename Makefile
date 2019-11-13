SHELL = bash


IMAGE_NAME = ci-cd-demo
K8S_NAMESPACE = default
# Can toggle this to either use the commit or digest for CD in k8s
USE_IMAGE_DIGEST_FOR_K8S = true

BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
# Will only exist locally after an image push
IMAGE_DIGEST = $(shell if [[ -f IMAGE_DIGEST ]]; then cat IMAGE_DIGEST; fi)
VCS_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
VCS_COMMIT = $(shell git rev-parse HEAD)
# Ignoring case where someone clones with https and include a username and password - you wouldn't do that ?
VCS_URL = $(shell git remote get-url origin)
VERSION = $(shell cat VERSION)

# Derived
REPOSITORY_NAME = ${USER}/${IMAGE_NAME}
IMAGE_WITH_DIGEST = ${REPOSITORY_NAME}@${IMAGE_DIGEST}
IMAGE_WITH_LATEST_TAG = ${REPOSITORY_NAME}:latest
IMAGE_WITH_TAG = ${REPOSITORY_NAME}:${VCS_COMMIT}
ifeq ($(USE_IMAGE_DIGEST_FOR_K8S),true)
	K8S_DEPLOYMENT_IMAGE = ${IMAGE_WITH_DIGEST}
else
	K8S_DEPLOYMENT_IMAGE = ${IMAGE_WITH_TAG}
endif


# Local image work
build-image:
	@# Using --pull - note if offline this will fail
	@# Also tagging with latest - do we really want to encourage this
	@docker image build \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--build-arg VCS_BRANCH=${VCS_BRANCH} \
		--build-arg VCS_COMMIT=${VCS_COMMIT} \
		--build-arg VCS_URL=${VCS_URL} \
		--build-arg VERSION=${VERSION} \
		--pull \
		--tag ${IMAGE_WITH_TAG} \
		--tag ${IMAGE_WITH_LATEST_TAG} \
		.


inspect-image-labels:
	@docker image inspect ${IMAGE_WITH_TAG} | jq .[0].Config.Labels


run-container:
	@docker container run --detach --rm --name ${IMAGE_NAME} ${IMAGE_WITH_TAG}


tail-container-log:
	@docker container logs ${IMAGE_NAME} --follow


kill-container:
	@docker container rm --force ${IMAGE_NAME}


# Image repository work
push-image:
	@# Assumes you have already done a docker login, going to push both latest and commit based images
	@# Reminder, tried to use DIG=$(docker ...), this will not work in Make as will evaluate before running the target commands - that hurt
	@# Idea here is that the IMAGE_DIGEST is what CD uses, hence you update your deployments to use it, create PR in CD repo after signoff
	@docker image push ${IMAGE_WITH_LATEST_TAG}
	@docker image push ${IMAGE_WITH_TAG}
	@docker image inspect --format='{{index .RepoDigests 0}}' ${IMAGE_WITH_TAG} | cut -d '@' -f 2 > IMAGE_DIGEST


# k8s
# Assumes you have your KUBECONFIG sorted and have done an image push - so we have a local IMAGE_MANIFEST file
deploy-to-k8s:
	@cat k8s.yaml | sed "s|image:.*|image: ${K8S_DEPLOYMENT_IMAGE}|" | kubectl apply --namespace ${K8S_NAMESPACE} -f -


list-k8s-pods:
	@kubectl get pods --namespace ${K8S_NAMESPACE} --selector app.kubernetes.io/name=${IMAGE_NAME}


inspect-k8s-pod-images:
	@kubectl get pods --namespace ${K8S_NAMESPACE} --selector app.kubernetes.io/name=${IMAGE_NAME} --output json | jq -r .items[].spec.containers[0].image


tail-k8s-pod-logs:
	@kubectl logs --namespace ${K8S_NAMESPACE} deploy/${IMAGE_NAME} --follow


delete-k8s-pods:
	kubectl delete deployment --namespace ${K8S_NAMESPACE} ${IMAGE_NAME}
