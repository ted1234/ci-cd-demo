ARG        ALPINE_VERSION=3.10

FROM       alpine:${ALPINE_VERSION}

# Should take care of your dependencies first so we get layer caching
# Should use specific versions, but we still can't trust this
# Can look at tools that just do file overlays if you want more safety
RUN        apk update && apk add curl=7.66.0-r0

# These need to come after the dependencies so we get to use a cache when building
ARG        BUILD_DATE=unspecified
ARG        VCS_BRANCH=unspecified
ARG        VCS_COMMIT=unspecified
ARG        VCS_URL=unspecified
ARG        VERSION=unspecified

# See https://github.com/opencontainers/image-spec/blob/master/annotations.md
LABEL      org.opencontainers.image.created=${BUILD_DATE}
LABEL      org.opencontainers.image.ref.name=${VCS_BRANCH}
LABEL      org.opencontainers.image.revision=${VCS_COMMIT}
LABEL      org.opencontainers.image.source=${VCS_URL}
LABEL      org.opencontainers.image.version=${VERSION}

# Simulating a binary with the version and git info embedded, i.e. we have a "./binary version" or "./binary --version"
WORKDIR    /usr/local/bin
COPY       app.sh .
RUN        sed -i "s/^VERSION=.*/VERSION=${VERSION}/; s/^VCS_COMMIT=.*/VCS_COMMIT=${VCS_COMMIT}/" app.sh 

# Lets not run as default root user, can override with a k8s security context, but this is good practise
USER       nobody:nogroup

ENTRYPOINT ["/usr/local/bin/app.sh"]
