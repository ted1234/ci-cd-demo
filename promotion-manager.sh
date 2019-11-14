#!/bin/bash
set -e


abc-update-git-with-env-values() {
	# This is outside this
	# env commit digest
	

	git branch -b "promote-to-$env-for-$commit-on-${timestamp}"
	update env values in env file
	git commit
	git push
	git create PR
}







update-git-with-env-values() {
	env=${1}
	source_commit=${2}
	image_digest=${3}

	update-env-values-file ${env} ${source_commit} ${image_digest}
	commit_message="Updating values for ${env} on source commit ${commit}"
	git commit -am "${commit_message}"
	git push
}

update-env-values-file() {
	env=${1}
	source_commit=${2}
	image_digest=${3}

	# Crude but good enough for here
	sed_arg=
	sed_arg+="s/^imageDigest:.*/imageDigest: ${image_digest}/; "
	sed_arg+="s/^sourceCommit:.*/sourceCommit: ${source_commit}/; "

	sed -i "${sed_arg}" ${env}.values.yaml
}


# Main
"$@"
