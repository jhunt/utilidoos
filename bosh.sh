# bashrc for BOSH hacking

#
# Wrap the main bosh command to support injected sub-commands
#
#  bosh route          Recreate the local BOSH-lite host routes
#  bosh curl           curl the BOSH director (with auth)
#  bosh msync          Download all the manifests!
#  bosh rere           Recreate release + upload release + deploy
#
#  bosh *              Hand off to the main bosh binary
#
bosh() {
    case ${1} in
    (route)
        sudo ip route del 10.244.0.0/16 && \
        sudo ip route add 10.244.0.0/16 via 192.168.50.4
        return $?
        ;;
    (ddnore)
        bosh delete-deployment
        \bosh create-release --timestamp-version --force && \bosh upload-release && \bosh -n deploy ${BOSH_MANIFEST:?set BOSH_MANIFEST first}
        return $?
        ;;

    (dd)
        bosh delete-deployment
        ;;

    (curl)
        url=$2
        if [[ -z ${url} ]]; then
            echo >&2 "Usage: bosh curl relative-url"
            return 1
        fi
        config=${BOSH_CONFIG:-$HOME/.bosh_config}
        target=$(  spruce json $config | jq -r .target)
        username=$(spruce json $config | jq -r '.auth["'${target}'"].username')
        password=$(spruce json $config | jq -r '.auth["'${target}'"].password')
        curl -Lsk --basic --user "${username}:${password}" "${target}/${url}"
        return $?
        ;;

    # broken
    #(msync)
    #    dest=$2
    #    if [[ -z ${dest} ]]; then
    #        echo >&2 "Usage: bosh msync /path/to/save/to"
    #        return 1
    #    fi

    #    mkdir -p ${dest}
    #    for deployment in $(bosh curl /deployments | jq -r .[].name); do
    #        bosh download manifest ${deployment} ${dest}/${deployment}.yml
    #    done
    #    return 0
    #    ;;

    (is)
        if [[ -n "$2" ]]; then
            export BOSH_ENVIRONMENT="$2"
            if [[ -n "$3" ]]; then
                export BOSH_DEPLOYMENT="$3"
            fi
        fi
        echo "bosh director: ${BOSH_ENVIRONMENT:-(not set)}"
        echo "deployment:    ${BOSH_DEPLOYMENT:-(not set)}"
        return 0
        ;;

    (clear)
        unset BOSH_ENVIRONMENT BOSH_DEPLOYMENT BOSH_MANIFEST
        return 0
        ;;

    (rere)
        \bosh create-release --timestamp-version --force && \bosh upload-release && \bosh -n deploy ${BOSH_MANIFEST:?set BOSH_MANIFEST first}
        return $?
        ;;

    (*)
        command bosh "$@"
        return $?
        ;;
    esac
}
