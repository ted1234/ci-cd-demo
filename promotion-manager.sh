#!/bin/bash
set -e

# Main command functions
promote-using-a-pr() {
	github_pat=${1}
	env=${2}
	source_commit=${3}
	source_short_commit=${4}
	image_digest=${5}

	initial_branch=$(git rev-parse --abbrev-ref HEAD)
	pr_branch="promote-to-${env}-for-source-commit-${source_short_commit}"

	git checkout -b ${pr_branch}
	commit-with-env-values $env ${source_commit} ${source_short_commit} ${image_digest}
	git push --set-upstream origin ${pr_branch}
	git push

	# Create PR
	# See https://developer.github.com/v3/pulls/#create-a-pull-request
	pr_url=$(get-repo-pr-url)
	pr_payload=$(printf '{"base": "%s", "body": "%s", "head": "%s", "title": "%s"' master "Please accept" ${pr_branch} ${pr_branch})
	curl -X POST -H "Authorization: token ${github_pat}" -H 'Content-Type: application/json' -d "${pr_payload}" ${pr_url}

	git checkout ${initial_branch}
}

promote-on-current-branch() {
	env=${1}
	source_commit=${2}
	source_short_commit=${3}
	image_digest=${4}

	commit-with-env-values $env ${source_commit} ${source_short_commit} ${image_digest}
	git push
}


# Helper functions
commit-with-env-values() {
	env=${1}
	source_commit=${2}
	source_short_commit=${3}
	image_digest=${4}

	values_file_name=$(get-env-values-file-name ${env})

	update-env-values-file ${values_file_name} ${source_commit} ${source_short_commit} ${image_digest}

	commit_message="Promoted values in ${values_file_name} on source commit ${source_commit}"
	git commit -am "${commit_message}"
}

get-env-values-file-name() {
	echo ${env}.values.yaml
}

get-repo-pr-url() {
	remote=${1:-origin}

	origin_url=$(git remote get-url --push ${remote})
	org_and_repo=
	if [[ ${origin_url} == git@* ]]; then
		org_and_repo=$(echo ${origin_url} | awk -F '(github\.com:)|(\.git)' '{print $2}')
	elif [[ ${origin_url} == https://* ]]; then
		org_and_repo=$(echo ${origin_url} | awk -F '(github\.com)|(\.git)' '{print $2}')
	else
		echo "Unhandled remote, cannot parse, exiting" && exit 1
	fi

	# See https://developer.github.com/v3/
	# See https://developer.github.com/v3/pulls/#create-a-pull-request
	echo "https://api.github.com/repos/${org_and_repo}/pulls"
}

update-env-values-file() {
	file_name=${1}
	source_commit=${2}
	source_short_commit=${3}
	image_digest=${4}

	# Crude but good enough for here
	sed_arg=
	sed_arg+="s/^imageDigest:.*/imageDigest: ${image_digest}/; "
	sed_arg+="s/^sourceCommit:.*/sourceCommit: ${source_commit}/; "
	sed_arg+="s/^sourceShortCommit:.*/sourceShortCommit: ${source_short_commit}/; "

	sed -i "${sed_arg}" ${file_name}
}


# Main
"$@"
