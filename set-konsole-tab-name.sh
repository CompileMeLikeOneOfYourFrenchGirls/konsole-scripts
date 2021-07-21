#! /bin/bash

titleLocal=${1:-%d : %n}
titleRemote=${2:-(%u) %H}

set-konsole-tab-title-type () {

local _title="$1"
local _type=${2:-0}
[[ -z "${_title}" ]] && return 1
[[ -z "${KONSOLE_DBUS_SERVICE}" ]] && return 1
[[ -z "${KONSOLE_DBUS_SESSION}" ]] && return 1

qdbus-qt5 >/dev/null "${KONSOLE_DBUS_SERVICE}" "${KONSOLE_DBUS_SESSION}" setTabTitleFormat "${_type}" "${_title}"
}

set-konsole-tab-title () {

set-konsole-tab-title-type "$titleLocal" && set-konsole-tab-title-type "$titleRemote" 1

}
