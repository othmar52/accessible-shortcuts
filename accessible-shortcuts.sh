#!/usr/bin/env bash
# requires http://www.semicomplete.com/projects/xdotool/

# configuration
MILISECONDS_TRIGGER=2000
MILISECONDS_IDLE=3000
TRIGGER_KEYCODE=37 # 37 = Ctrl
REQUIRED_TRIGGER_EVENT_AMOUNT=9

function debugmsg {
  return # disabled debugoutput
  echo $1
}

function resetRuntimeVariables {
  debugmsg "resetRuntimeVariables()"
  RECORDING_START=0
  RECORDED_TRIGGER_EVENTS=0
  TRIGGER_COMPLETE=0
}

function fire {
  sleep 0.1 # no idea why this is not working without this sleep!? but who cares...
  xdotool key $1
}

resetRuntimeVariables
xinput test-xi2 --root | while read line;do
  if [[ $RECORDING_START -gt 0 ]];then
    RUNTIME=$( date +%s%N | cut -b1-13 )-$RECORDING_START
    if [[ $RUNTIME -gt $MILISECONDS_IDLE ]];then
      debugmsg "reset recording with runtime $RUNTIME ms"
      resetRuntimeVariables
    fi
  fi

  if [[ "$line" == "detail: $TRIGGER_KEYCODE" ]];then
    if [[ $RECORDING_START -eq 0 ]];then
      debugmsg "Start recording..."
      RECORDING_START=$( date +%s%N | cut -b1-13 )
    else
      RECORDED_TRIGGER_EVENTS=$(($RECORDED_TRIGGER_EVENTS+1))
      debugmsg "got trigger during recording time total: $RECORDED_TRIGGER_EVENTS"
    fi
      
    if [[ $RECORDED_TRIGGER_EVENTS -gt $REQUIRED_TRIGGER_EVENT_AMOUNT ]];then
      debugmsg "TRIGGER COMPLETE: lets record next keystroke..."
      TRIGGER_COMPLETE=1
    fi
  fi
  if [[ $TRIGGER_COMPLETE -eq 1 ]] && [[ $line =~ detail\:\ ([[:digit:]]+) ]];then
    KEYCODE=${BASH_REMATCH[1]}
    if [[ "$KEYCODE" -eq "$TRIGGER_KEYCODE" ]] || [[ "$KEYCODE" -eq "0" ]];then
      continue
    fi
    LOOKUP=$( xmodmap -pke | grep "keycode\([\ ]*\)$KEYCODE\([\ ]*\)" | awk '{ print $4 }' )
    if [ ! -z "$LOOKUP" ];then
      fire "ctrl+$LOOKUP"
      resetRuntimeVariables
    fi
  fi
done
