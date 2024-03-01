# TODO: make it work if the completions is asked from the middle
# TODO: make it not repeat the same entries
# TODO: make switches with parameters work

lpm_switches="
  --json --verbose
  --quiet --version
  --help --assume-yes
  --no-install-optional
  --trace --progress
  --symlink --reinstall
  --no-color --table
  --repository
  --ephemeral --mask
  --force --post
  --remotes
"

function _lpm_clean_switches()
{
  local cleaned=()
  for entry in "${COMP_WORDS[@]}";
  do
    if ! [[ $entry =~ ^- ]]; then
      cleaned+=("$entry")
    fi
  done
  COMP_WORDS=("${cleaned[@]}")
}

function _lpm_list_addons()
{
  local filter=""
  if [[ "$1" ]]; then
    filter="--type $1"
  fi

  # shellcheck disable=SC2086 # Intended splitting of filter
  COMPREPLY+=($(compgen -W "$(lpm list $filter --raw 'id')" -- "${COMP_WORDS[-1]}"))
}

function _lpm_list_installed_addons()
{
  local filter=""
  if [[ "$1" ]]; then
    filter="--type $1"
  fi

  # shellcheck disable=SC2086 # Intended splitting of filter
  COMPREPLY+=($(compgen -W "$( (
                lpm list $filter --raw 'id' --status=installed;\
                lpm list $filter --raw 'id' --status=upgradable;\
                lpm list $filter --raw 'id' --status=orphan;\
              ) )" -- "${COMP_WORDS[-1]}"))
}

function _lpm_addon_completions()
{
  local addon_commands="install uninstall reinstall list"
  if [ "${#COMP_WORDS[@]}" == "3" ]; then
    COMPREPLY+=($(compgen -W "${addon_commands}" -- "${COMP_WORDS[2]}"))
    return
  fi
  case ${COMP_WORDS[2]} in
    install) _lpm_list_addons "$1" ;;
    uninstall) _lpm_list_installed_addons "$1" ;;
    reinstall) _lpm_list_installed_addons "$1" ;;
    list) ;;
  esac
}

function _lpm_repo_completions()
{
  local repo_commands="list add rm update"
  if [ "${#COMP_WORDS[@]}" == "3" ]; then
    COMPREPLY+=($(compgen -W "${repo_commands}" -- "${COMP_WORDS[2]}"))
    return
  fi
  case ${COMP_WORDS[2]} in
    list) ;;
    add) ;;
    rm) COMPREPLY+=($(compgen -W "$(lpm repo list | awk '/Remote /{print $3}')" -- "${COMP_WORDS[-1]}"\
                      | awk '{ print "'\''"$0"'\''" }')) ;; # the last awk is needed to quote the result that contains characters that might prematurely split (https://stackoverflow.com/a/71410674)
    update) ;;
  esac
}

function _lpm_list_versions()
{
  COMPREPLY+=($(compgen -W "$(lpm lite-xl list | awk 'NR>2{print $1}')" -- "${COMP_WORDS[-1]}"))
}

function _lpm_run_completions()
{
  _lpm_list_addons
  _lpm_list_versions
}

function _lpm_completions()
{
  local base_commands="
    init
    repo add rm update
    plugin library color install uninstall reinstall list
    upgrade
    lite-xl switch
    run describe purge help
    test exec download hash
    update-checksums extract
  "

  # Autocomplete a switch if it's the last element
  if [[ "${COMP_WORDS[-1]}" =~ ^- ]]; then
    COMPREPLY+=($(compgen -W "${lpm_switches}" -- "${COMP_WORDS[-1]}"))
    return
  fi

  # Remove all switches, as they can be in any position
  # and generally don't alter command interpretation
  #_lpm_clean_switches

  if [ "${#COMP_WORDS[@]}" == "2" ]; then
    COMPREPLY+=($(compgen -W "${base_commands}" -- "${COMP_WORDS[1]}"))
    return
  fi

  case ${COMP_WORDS[1]} in
    repo) _lpm_repo_completions ;;
    install) _lpm_list_addons ;;
    uninstall) _lpm_list_installed_addons ;;
    reinstall) _lpm_list_installed_addons ;;
    plugin|color|library) _lpm_addon_completions "${COMP_WORDS[1]}" ;;
    run) _lpm_run_completions ;;
  esac
}

complete -F _lpm_completions lpm
