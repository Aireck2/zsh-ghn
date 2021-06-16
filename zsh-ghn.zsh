#!/usr/bin/env ksh
# -*- coding: utf-8 -*-

GHQ_ROOT=$(ghq root)
GHQ_ROOT_DIR=$(dirname "$0")
GHQ_SRC_DIR="${GHQ_ROOT_DIR}"/src
GHQ_CACHE_DIR="${HOME}/.cache/ghq"
GHQ_CACHE_NAME="ghq.txt"
GHQ_CACHE_PROJECT="${GHQ_CACHE_DIR}/${GHQ_CACHE_NAME}"

GHQ_REGEX_IS_REPOSITORY="^(git:|git@|ssh://|http://|https://)"
# GITHUB_USER="$(git config github.user)"

# ghq_package_name='ghq'

# ghq list simplify
function ghq::projects::list() {
    if [ ! -e "${GHQ_CACHE_PROJECT}" ]; then
        ghq::cache::create::factory
        ghq::cache::list
    else
        ghq::cache::list
    fi
}

function ghq::cache::create::factory() {
    ghq::cache::create
}

function ghq::cache::create() {
    [ -e "${GHQ_CACHE_DIR}" ] || mkdir -p "${GHQ_CACHE_DIR}"
    ghq list >"${GHQ_CACHE_PROJECT}"
}

function ghq::find::project() {
    if type -p fzf >/dev/null; then
        local buffer
        buffer=$(ghq::projects::list | fzf)
        if [ -n "${buffer}" ]; then
            # shellcheck disable=SC2164
            cd "$(ghq root)/${buffer}"
        fi
    fi
}

function ghq::cache::list() {
    [ -e "${GHQ_CACHE_PROJECT}" ] && cat "${GHQ_CACHE_PROJECT}"
}

# ghq get simplify
function ghq::new::template() {
    local template repository_path
    repository_path="$(ghq root)/github.com/${GITHUB_USER}/"
    template="$(ghq::cookiecutter::find)"
    if [ -z "${template}" ]; then
        message_warning "Please Select one Project"
        return
    fi
    cd "${repository_path}" || cd - &&
        eval "cookiecutter ${template}" &&
        ghq::cache::clear
}

function ghq::cookiecutter::find() {
    local command_value
    command_value=$(
        ghq::cookiecutter::list |
            fzf |
            awk 'BEGIN{FS="\t"; OFS=""} {print $4}' |
            ghead -c -1
    )

    if [ -n "${command_value}" ]; then
        echo -e "${command_value}"
    fi
}

function ghq::cookiecutter::list() {
    # shellcheck disable=SC2002
    cat "${GHQ_FILE_COOKIECUTTER}" |
        jq -r '.projects[] | [.name, .type, .description, .repository] | @tsv' |
        sed 's/"//g'
}

function ghq::new() {
    local repository repository_path
    repository="${1}"
    repository_path="$(ghq root)/github.com/${GITHUB_USER}/${repository}"
    ghq create "${repository}"
    ghq::cache::clear
    cd "${repository_path}" || cd - && git flow init -d
}

function ghq::factory() {
    local repository repository_path is_repository
    repository="${1}"
    is_repository=$(echo "${repository}" | grep -cE "${GHQ_REGEX_IS_REPOSITORY}")

    if [ -z "${repository}" ]; then
        ghq::new::template
        return
    fi

    if [ "${is_repository}" -eq 1 ]; then
        ghq get "${repository}"
        ghq::cache::clear
        return
    fi

    ghq::new "${repository}"

}

function ghq::cache::clear() {
    [ -e "${GHQ_CACHE_PROJECT}" ] && rm -rf "${GHQ_CACHE_PROJECT}"
    ghq::cache::create::factory
}

alias ghn=ghq::factory

zle -N ghq::find::project
#Press Ctrl+X+P
bindkey '^XP' ghq::find::project
