#! /bin/bash

[ "${BASH_SOURCE[0]}" == "${0}" ] || {
    printf "${BASH_SOURCE[0]##*/}: %s\n" \
        "This file is not meant to be sourced.."
    return 1
} \
    1>&2

function shimmed ()
{

    declare vars_sl_=(
        fnc
        run
        tmp
        ent
        SHIMMED_RUND
        SHIMMED_BIND
        SHIMMED_NAME
        SHIMMED_PATH
        SHIMMED_BASE
        tc_spc tc_tab tc_nln
        tc_tilde tc_fslash
        IFS_DEF
        IFS_TAN IFS_NLN
        IFS_RGX
    )

    declare vars_slx=(
        IFS
    )

    declare vars_al_=(
        fnc_msg
        SHIMMED_HEAD
        SHIMMED_HIND
        SHIMMED_EXEC
        SHIMMED_ARGS
    )

    declare vars_il_=(
        fnc_debug
        fnc_return
        flg_help
        I J K
    )

    declare vars____=(
        ${vars_sl_[*]} ${vars_slx[*]}
        ${vars_al_[*]}
        ${vars_il_[*]}
    )

    declare     ${vars_sl_[*]}
    declare  -x ${vars_slx[*]}
    declare -a  ${vars_al_[*]}
    declare -i  ${vars_il_[*]}

    fnc="${FUNCNAME[0]}"
    fnc_msg=( printf "\n${fnc}: %s\n" )
    fnc_return=0
    fnc_debug="${DEBUG_SHIMMED:-${SHIMMED_DEBUG:-0}}"

    printf -v tc_spc ' '
    printf -v tc_tab '\t'
    printf -v tc_nln '\n'

    printf -v tc_tilde  '~'
    printf -v tc_fslash '/'

    printf -v IFS_DEF   ' \t\n'
    printf -v IFS_TAN   '\t\t\n'
    printf -v IFS_NLN   '\n\n\n'
    printf -v IFS_RGX   '|\t\n'
    IFS="${IFS_DEF}"

    shimmed_not_directly_called || return "${?}"

    shimmed_has_xdg_vars_set || return "${?}"

    SHIMMED_RUND="${PWD}"
    SHIMMED_BIND="${BASH_SOURCE[0]%/*}"
    [ "${SHIMMED_BIND:0:1}" == / ] || {
        cd "${SHIMMED_BIND}"
        SHIMMED_BIND="${PWD}"
        cd "${SHIMMED_RUND}"
    }
    SHIMMED_NAME="${BASH_SOURCE[0]##*/}"
    SHIMMED_PATH="${SHIMMED_BIND}/${SHIMMED_NAME}"

    shimmed_find_base

    for ent in "${SHIMMED_BASE}"/shimmed.{,d/,my.d/}*.bash
    do
        [ -r "${ent}" ] || continue
        case "${ent//${tc_fslash}/.}" in
        ( *.head.bash ) SHIMMED_HEAD=( "${SHIMMED_HEAD[@]}" "${ent}" );;
        ( *.hind.bash ) SHIMMED_HIND=( "${SHIMMED_HIND[@]}" "${ent}" );;
        esac
    done

    SHIMMED_ARGS=( "${@}" )
    for ent in ${PATH//:/ }
    do
        [ "${ent}" != "${SHIMMED_BIND}" ] || continue
        ent="${ent}/${SHIMMED_NAME}"
        [ -x "${ent}" ] || continue
        SHIMMED_EXEC=( "${ent}" )
        break
    done

    [ "${fnc_debug:-0}" -lt 1 ] \
    || {
            "${fnc_msg[@]}" "PATH.."
            declare -p PATH
            "${fnc_msg[@]}" "INIT.."
            declare -p ${!SHIMMED*}
    } 1>&2

    [ "${fnc_debug:-0}" -lt 2 ] && run=( . ) || run=( printf '. %s\n' )

    [ "${fnc_debug:-0}" -lt 1 ] || "${fnc_msg[@]}" "HEAD.." 1>&2

    for ent in "${SHIMMED_HEAD[@]}"
    do
        "${run[@]}" "${ent}" || {
            fnc_return="${?}"
            "${fnc_msg[@]}" "HEAD ( ${ent} ) ERR [ ${fnc_return} ]"
            return "${fnc_return}"
        }
    done

    [ "${fnc_debug:-0}" -lt 1 ] || declare -p SHIMMED_ARGS SHIMMED_EXEC 1>&2

    [ "${fnc_debug:-0}" -lt 2 ] && {
        [ "${#SHIMMED_HIND[@]}" -gt 0 ] \
            && run=() \
            || run=( exec )
    } || {
        [ "${#SHIMMED_HIND[@]}" -gt 0 ] \
            && run=( printf '%s\n' ) \
            || run=( printf 'exec %s\n' )
    }

    [ "${fnc_debug:-0}" -lt 1 ] || "${fnc_msg[@]}" "RUN.." 1>&2

    "${run[@]}" "${SHIMMED_EXEC[@]}" "${SHIMMED_ARGS[@]}"

    fnc_return="${?}"

    [ "${#SHIMMED_HIND[@]}" -gt 0 ] || return "${fnc_return}"

    [ "${fnc_debug:-0}" -lt 1 ] || declare -p fnc_return 1>&2

    [ "${fnc_debug:-0}" -lt 2 ] && run=( . ) || run=( printf '%s\n' )

    [ "${fnc_debug:-0}" -lt 1 ] || "${fnc_msg[@]}" "HIND.." 1>&2

    for ent in "${SHIMMED_HIND[@]}"
    do
        "${run[@]}" "${ent}" || {
            fnc_return="${?}"
            "${fnc_msg[@]}" "HIND ( ${ent} ) ERR [ ${fnc_return} ]"
            return "${fnc_return}"
        }
    done

}

function shimmed_not_directly_called ()
{
    [ "${BASH_SOURCE[0]##*/}" == "shimmed" ] || return 0
    printf "shimmed: %s\n" \
        "Why: Shimmed is a wrapper system, which is run via a symlink" \
        "     with the name of the binary for which wrapping is desired." \
        "Use: Create a symlink to 'shimmed'. Execute said symlink." \
        1>&2
    return 1
}

function shimmed_has_xdg_vars_set ()
{
    declare I J K L M N O
    I=( XDG_{{CONFIG,DATA,CACHE}_HOME,RUNTIME_DIR} )
    M=0
    N=0
    O=()
    for (( J=0; J<${#I[*]}; J++ ))
    do
        K="${I[${J}]}"
        printf -v L 'L="${%s:-}"' "${K}"
        eval "${L}"
        [ -n "${L:-}" ] && M=0 || {
            let M=2**J
            O=( "${O[@]}" "${K}" )
        }
        let N+=M
    done
    [ "${N}" -eq 0 ] || {
        let N+=1000
        printf "shimmed: %s\n" \
            "Why: Shimmed uses XDG Base Directory Specification." \
            "     The following environment variables are unset::" \
            "${O[@]/#/     }"
    } 1>&2
    return "${N}"
}

function shimmed_find_base ()
{

    declare lnk tgt rgx

    tgt="${SHIMMED_PATH}"

    until [[ "${tgt}" =~ ^(.*/)?shimmed$ ]]
    do
        lnk="${tgt}"
        tgt="$( ls -lond "${lnk}" )"
        printf -v rgx '^[^/]+%s(.*)$' "${lnk}"
        [[ "${tgt}" =~ ${rgx} ]] || break
        tgt="${BASH_REMATCH[1]}"
        printf -v rgx '^ -> (.*)$'
        [[ "${tgt}" =~ ${rgx} ]] || break
        tgt="${BASH_REMATCH[1]}"
        [[ "${tgt}" != */* ]] || break
        tgt="${lnk%/*}/${tgt}"
    done

    SHIMMED_BASE="${XDG_CONFIG_HOME}/${lnk##*/}"

}

shimmed "${@}"
