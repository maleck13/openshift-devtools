#!/bin/bash

function rebuild-openshift-image() {
  source "$(dirname ${BASH_SOURCE})/../common.sh"

  set -e

  image="$1"
  base_image="${image}-base"

  tmpdir="$(mktemp -d)"
  openshiftbin="$(which openshift)"

  info "Copying openshift binary to temporary work directory ..."
  cp -av "${openshiftbin}" "${tmpdir}"

  # Find base image id to avoid stacking multiple COPY layers
  base_id=$(docker history --no-trunc ${image} | \
            grep -v 'COPY file.*in /usr/bin/openshift' | \
            awk 'NR==2 {print $1}')

  info "Tagging the base Docker image ${base_image} ..."
  docker tag "${base_id}" "${base_image}"

  # Write Dockerfile
  set +e
  read -d '' Dockerfile <<EOF
  FROM ${base_image}

  COPY openshift /usr/bin/openshift
EOF
  set -e
  echo "${Dockerfile}" > ${tmpdir}/Dockerfile

  info "Building Docker image ${image} ..."
  docker build -t "${image}" "${tmpdir}"

  # Cleanup
  rm -vrf "${tmpdir}"

  info "Done."
}