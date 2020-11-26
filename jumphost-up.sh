#!/usr/bin/env bash

JUMPHOST_FORCE_RM_FLAG=0
JUMPHOST_FILE_YML="${OPENSSH_YML:-docker-compose.yml}"
JUMPHOST_FILE_ENV="${OPENSSH_ENV:-openssh.env}"
JUMPHOST_FILE_SECRET_USER_PASSWD="${OPENSSH_SECRET_USER_PASSWD:-sshd/secrets/user_password.txt}"
JUMPHOST_FILE_SSHD_CONFIG="${JUMPHOST_SSHD_CONFIG:-sshd/data/ssh_host_keys/sshd_config}"
JUMPHOST_FILE_AUTHORIZED_KEYS="${JUMPHOST_AUTHORIZED_KEYS:-sshd/data/.ssh/authorized_keys}"
JUMPHOST_STACK_NAME="${STACK_NAME:-jumphost}"

if [[ -n "${1}" ]] && [[ "${1}" == "--force-rm" ]]; then
  JUMPHOST_FORCE_RM_FLAG=1
fi

createConfigIfNotExists() {
  while [[ $# -gt 0 ]]
  do
    _name=$(basename "${1}")
    _file=(${_name//./ })
    _file[0]=$(echo "${_file[0]//// }" | awk '{ print $NF }')

    if [[ "${JUMPHOST_FORCE_RM_FLAG}" -eq 1 ]] &&
        [[ "${_file[0]}" != "user_password" ]] &&
        [[ "${_file[0]}" != "authorized_keys" ]]; then

      echo "WARNING: Force rm flag is set"
      rm -rf "${1}"
    fi

    case "${_file[0]}" in
      docker-compose)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}.example.${_file[1]}" "${JUMPHOST_FILE_YML}"
        else
          echo " • ${1} exists. Skip"
        fi
        ;;
      openssh)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}.example.${_file[1]}" "${JUMPHOST_FILE_ENV}"
        else
          echo " • ${1} exists. Skip"
        fi
        ;;
      sshd_config)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}" "${JUMPHOST_FILE_SSHD_CONFIG}"
        else
          echo " • ${1} exists. Skip"
        fi
        ;;
      authorized_keys)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          cp "config/${_file[0]}" "${JUMPHOST_FILE_AUTHORIZED_KEYS}"
        else
          echo " • ${1} exists. Skip"
        fi
        ;;
      user_password)
        if [[ ! -f "${1}" ]]; then
          echo " + ${1} doesn't exist. Create"
          openssl rand -base64 17 > "${JUMPHOST_FILE_SECRET_USER_PASSWD}"
        else
          echo " • ${1} exists. Skip"
        fi
        ;;
    esac

    shift
  done
}

configure() {
  echo "Starting configure:"

  createConfigIfNotExists \
    "${JUMPHOST_FILE_YML}" \
    "${JUMPHOST_FILE_ENV}" \
    "${JUMPHOST_FILE_SSHD_CONFIG}" \
    "${JUMPHOST_FILE_AUTHORIZED_KEYS}" \
    "${JUMPHOST_FILE_SECRET_USER_PASSWD}"
}

up() {
  echo "Running ${JUMPHOST_STACK_NAME} stack"

  echo "Added label to node:" \
    $(docker node update --label-add openssh=true \
      $(docker node inspect self --format '{{ .Description.Hostname }}'))
  docker stack up -c docker-compose.yml "${JUMPHOST_STACK_NAME}"
}

main() {
  configure
  up
}

main "$@"