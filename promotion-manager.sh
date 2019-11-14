#!/bin/bash
set -e

# Main command functions
promote-using-a-pr() {
	env=${1}
	source_commit=${2}
	image_digest=${3}

	git branch -b "promote-to-$env-for-source-commit-$commit"
	commit-with-env-values $env ${source_commit} ${image_digest}
	git set
	git push
	# Create PR
}

promote-on-current-branch() {
	env=${1}
	source_commit=${2}
	image_digest=${3}

	commit-with-env-values $env ${source_commit} ${image_digest}
	git push
}


# Helper functions
commit-with-env-values() {
	env=${1}
	source_commit=${2}
	image_digest=${3}

	values_file_name=$(get-env-values-file-name ${env})

	update-env-values-file ${values_file_name} ${source_commit} ${image_digest}

	commit_message="Promoted values in ${values_file_name} on source commit ${source_commit}"
	git commit -am "${commit_message}"
}

get-env-values-file-name() { 
	echo ${env}.values.yaml 
}

update-env-values-file() {
	file_name=${1}
	source_commit=${2}
	image_digest=${3}

	# Crude but good enough for here
	sed_arg=
	sed_arg+="s/^imageDigest:.*/imageDigest: ${image_digest}/; "
	sed_arg+="s/^sourceCommit:.*/sourceCommit: ${source_commit}/; "

	sed -i "${sed_arg}" ${file_name}
}


# Main
"$@"
