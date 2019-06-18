#!/bin/bash
#
# Based on http://www.linuxjournal.com/content/start-and-control-konsole-dbus

#####################################################################

set -e

# starts sessions in Konsole
function start_sessions()
{
    declare -a sessions=($@)
    local konsole_service=${KONSOLE_SERVICE:-$(qdbus-qt5 | grep konsole | head -n1)}
    local session_count=${#sessions[*]}
    local i=0
    echo "Using Konsole service: $konsole_service"

    while [[ $i -lt $session_count ]]; do
        local name=${sessions[$i]}
        i=$((i + 1))
        local command=${sessions[$i]}
        i=$((i + 1))

        echo "Creating $name: $command"
        local session_num=$(qdbus-qt5 $konsole_service /Windows/1 newSession)
        sleep 0.1
        qdbus-qt5 $konsole_service /Sessions/$session_num setTitle 0 $name
        sleep 0.1
        qdbus-qt5 $konsole_service /Sessions/$session_num setTitle 1 $name
        sleep 0.1
        qdbus-qt5 $konsole_service /Sessions/$session_num sendText "openqa-start $command"
        sleep 0.1
        qdbus-qt5 $konsole_service /Sessions/$session_num sendText $'\n'
        sleep 0.1

        nsessions=$((nsessions + 1))
    done

     # activate first session
    while [[ $session_count -gt 1 ]]; do
        qdbus "$KONSOLE_SERVICE" /Konsole prevSession
        session_count=$((session_count - 1))
    done
}
