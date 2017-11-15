#!/usr/bin/env bash

_list_repo_branches() {
    echo "=== git repositories/branches and their last commit ===" > REPO_STATUS
    _list_repo_branches >> REPO_STATUS
    cat REPO_STATUS
    echo
}


_echo_repo_owner_name_branch() {
    git remote -v | head -1 | \
        perl -ne 'm{(git\@github.com:|https://github.com/)(\S+) }; print " - $2/"' | \
        perl -pe 's/\.git//'
    git symbolic-ref --short -q HEAD | tr -d '\n'
    printf ' '
}


_echo_last_commit() {
    git log -n1 | \
        grep -v  '^$' | \
        perl -pe '$_="#".substr($_,7,9) if /^commit/; s/^(Author:\s*|Date:\s*)/; /' | \
        tr -d '\n' | tr -s ' '
    echo
}

show_git_branches() {
# Show branches of all git repos in path
    find . -name '.git' | while read file; do
        repodir=$(dirname $file)
        cd $repodir
        _echo_repo_owner_name_branch
        [[ -e 'VERSION' ]] && echo -n '::' && cat VERSION | tr -d '\n'
        _echo_commit_status
        _echo_last_commit
        cd $OLDPWD
    done
}

_list_repo_branches