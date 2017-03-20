#!/bin/bash
# introduce and trust the PGP public key (for SHIVA - docker image verification)

main() {
    run_only_once
    import_and_trust_key
    mark_as_done
}


run_only_once() {
    if [ -e /tmp/set_gpg_trust.done ]; then
        exit 0
    fi
}


import_and_trust_key() {
    gpg2 --import /etc/pki/gpg/rhIdentineticsCom_pub.gpg
    echo -e "trust\n5\ny" > /tmp/gpg_editkey.cmd
    gpg2 --command-file /tmp/gpg_editkey.cmd --edit-key 904F1906
}


mark_as_done() {
    touch /tmp/set_gpg_trust.done
}

main $@