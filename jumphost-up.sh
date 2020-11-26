#!/usr/bin/env bash

JUMPHOST_FILE_YML="${OPENSSH_YML:-docker-compose.yml}"
JUMPHOST_FILE_ENV="${OPENSSH_ENV:-openssh.env}"
JUMPHOST_FILE_SSHD_CONFIG="${JUMPHOST_SSHD_CONFIG:-sshd/data/ssh_host_keys/sshd_config}"
JUMPHOST_FILE_AUTHORIZED_KEYS="${JUMPHOST_AUTHORIZED_KEYS:-sshd/data/.ssh/authorized_keys}"
JUMPHOST_STACK_NAME="${STACK_NAME:-jumphost}"


createConfigIfNotExists() {
  while [[ $# -gt 0 ]]
  do
    _file=(${1//./ })
    _file[0]=$(echo "${_file[0]//// }" | awk '{ print $NF }')

    case "${_file[0]}" in
      docker-compose)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}.example.${_file[1]}" "${JUMPHOST_FILE_YML}"
        else
          echo " • ${1} exists. Skip"
        fi
        shift
        ;;
      openssh)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}.example.${_file[1]}" "${JUMPHOST_FILE_ENV}"
        else
          echo " • ${1} exists. Skip"
        fi
        shift
        ;;
      sshd_config)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}" "${JUMPHOST_FILE_SSHD_CONFIG}"
        else
          echo " • ${1} exists. Skip"
        fi
        shift
        ;;
      authorized_keys)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}" "${JUMPHOST_FILE_AUTHORIZED_KEYS}"
        else
          echo " • ${1} exists. Skip"
        fi
        shift
        ;;
    esac
  done
}

configure() {
  echo "Starting configure:"

  createConfigIfNotExists "${JUMPHOST_FILE_YML}" "${JUMPHOST_FILE_ENV}" "${JUMPHOST_FILE_SSHD_CONFIG}" "${JUMPHOST_FILE_AUTHORIZED_KEYS}"
}

up() {
  echo "Running ${JUMPHOST_STACK_NAME} stack"

  docker node update --label-add openssh=true $(docker node inspect self --format '{{ .Description.Hostname }}')
  docker stack up -c docker-compose.yml "${JUMPHOST_STACK_NAME}"
}

main() {
  configure
  up
}

main "$@"