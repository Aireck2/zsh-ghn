#!/usr/bin/env ksh
# -*- coding: utf-8 -*-

GHQ_ROOT=$(ghq root)
GHQ_ROOT_DIR=$(dirname "$0")
GHQ_SRC_DIR="${GHQ_ROOT_DIR}"/src
GHQ_CACHE_DIR="${HOME}/.cache/ghq"
GHQ_CACHE_NAME="ghq.txt"
GHQ_CACHE_PROJECT="${GHQ_CACHE_DIR}/${GHQ_CACHE_NAME}"

# GHQ_REGEX_IS_REPOSITORY="^(git:|git@|ssh://|http://|https://)"
# GITHUB_USER="$(git config github.user)"

# ghq_package_name='ghq'

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

alias ghn=ghq::new

zle -N ghq::find::project
bindkey '^P' ghq::find::project
