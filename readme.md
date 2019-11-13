# What you will need
# Local tooling
- Docker
	- Dockerhub account if you want to push/share an image
- Make
- jq

## If you want to deploy will need
- kubectl
- Access to a k8s cluster



# Tags
- See "Best Practises" at https://success.docker.com/article/images-tagging-vs-digests
- Can use one of the following
	- Latest - Terrible - no idea what this means
	- Version in the tag - Not so great - mutable images
	- Commit in the tag - Better but still subject to image mutation, but does link back to a point in time in the source
	- Digest - Best practise

In this repo we
- Build an image with a tag based on the commit sha
	- We capture the image digest when we push the image, this needs to get forwarded to CD
	- We also use tag with the "latest" commit - is really for developer convenience, but has no place in a managed CI/CD
- Deploy using the image digest
- Will also add a bunch of labels to the image
- Will include the version in the image binary runtime, see log output



# Workflow
## Local development
```
# CI to build the image
make build image

# Inspect image labels
make inspect-image-labels

# Run a container
make run-container

# Tail container log
make tail-container-log
```

## Simulate CI
```
# CI to build the image
make build-image

# Inspect image labels
make inspect-image-labels

# Push image
make push-image

# Lets see the image digest - This should be pushed to CD so it uses it - PR on CD repo
cat IMAGE_DIGEST
```

## Simulate CD
Assumes a trigger has kicked this off
```
# Deploy
make deploy-to-k8s

# Inspect pod images
make inspect-k8s-pod-images

# Tail pod logs - see the version and git commit from image build time
make tail-k8s-pod-logs
```
