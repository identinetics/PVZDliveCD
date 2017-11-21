#!/usr/bin/env bash

_list_repo_branches() {
    echo "=== git repositories/branches and their last commit ===" > REPO_STATUS
    show_git_branches >> REPO_STATUS
    #cat REPO_STATUS
    #echo
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


_echo_commit_status() {
# output ahead/behind upstream status
    branch=`git rev-parse --abbrev-ref HEAD`
    git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | \
    while read local upstream; do
        # Use master if upstream branch is empty
        [[ -z $upstream ]] && upstream=master

        ahead=`git rev-list ${upstream}..${local} --count`
        behind=`git rev-list ${local}..${upstream} --count`

        if [[ $local == $branch ]]; then
            # Does this branch is ahead or behind upstream branch?
            if [[ $ahead -ne 0 && $behind -ne 0 ]]; then
                echo -n " ($ahead ahead and $behind behind $upstream) "
            elif [[ $ahead -ne 0 ]]; then
                echo -n " ($ahead ahead $upstream) "
            elif [[ $behind -ne 0 ]]; then
                echo -n " ($behind behind $upstream) "
            fi
            # Any locally modified files?
            count=$(git status -suno | wc -l | sed -e 's/ //g')
            (( "$count" > "0" )) && echo -n " ($count file(s) locally modified) "
        fi
    done;
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