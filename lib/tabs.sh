#!/bin/bash
#
# Based on http://www.linuxjournal.com/content/start-and-control-konsole-dbus

#####################################################################

set -e
set -x # DEBUG, REMOVE LATER

# starts sessions in Konsole, Tilix, or tmux
function start_sessions()
{
    declare -n term_sessions=$1
    if [[ $KONSOLE_DBUS_SESSION ]]; then
        local konsole_service=${KONSOLE_SERVICE:-$(qdbus-qt5 | grep konsole | head -n1)}
        echo "Using Konsole service: $konsole_service"
    elif [[ $TILIX_ID ]]; then
        echo "Tilix detected. Using keyboard emulation for session management."
    else
        # start tmux session as fallback
        tmux new -d -s "openqa" -n "shell"
    fi

    local session_count=${#term_sessions[*]}
    local i=0

    while [[ $i -lt $session_count ]]; do
        local name=${term_sessions[$i]}
        i=$((i + 1))
        local command=${term_sessions[$i]}
        i=$((i + 1))

        echo "Creating $name: $command"
        if [[ $KONSOLE_DBUS_SESSION ]]; then
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
        elif [[ $TILIX_ID ]]; then
            echo "Splitting Tilix window and executing command: $name"
            xdotool key ctrl+alt+d # Split downwards
            sleep 0.5
            xdotool key ctrl+alt+Down # focus new terminal
            sleep 0.2 

            # TODO: fix this / find keybord layout agnostic solution
            xdotool type --delay 1 "openqa/start $command"
            #ydotool key 45  # 45 is the key code for minus (-)
            #xdotool type --delay 1 "start $command"
            
            xdotool key Return
            # xdotool key --clearmodifiers ctrl+alt+Up  # return focus to original pane
        else
            tmux neww -d -t "openqa:$((nsessions + 2))" -n "$name"
            tmux send -t "openqa:$name" "openqa-start $command" "Enter"
        fi

        nsessions=$((nsessions + 1))
    done

    # activate first session
    if [[ $KONSOLE_DBUS_SESSION ]]; then
        while [[ $session_count -gt 1 ]]; do
            qdbus-qt5 "$KONSOLE_SERVICE" /Konsole prevSession
            session_count=$((session_count - 1))
        done
    elif [[ $TILIX_ID ]]; then
        # tilix automatically activates the new pane
        echo "Tilix session activated"
    else
        tmux a -t openqa
    fi
}

