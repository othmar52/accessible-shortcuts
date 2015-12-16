#!/bin/env bash

# requires http://www.semicomplete.com/projects/xdotool/

MILISECONDS_TRIGGER=2000
MILISECONDS_IDLE=3000
# 37 = Ctrl keycode
LINE_TIGGER="detail: 37"
REQUIRED_TRIGGER_EVENT_AMOUNT=9
RECORDED_TRIGGER_EVENTS=0
TRIGGER_COMPLETE=0

RECORDING_START=0
xinput test-xi2 --root | while read line
do 
  #echo $line
  if [[ $RECORDING_START -gt 0 ]]
  then
    RUNTIME=$( date +%s%N | cut -b1-13 )-$RECORDING_START
    if [[ $RUNTIME -gt $MILISECONDS_IDLE ]]
    then
      #echo "reset recording with runtime $RUNTIME ms"
      RECORDING_START=0
      RECORDED_TRIGGER_EVENTS=0
      TRIGGER_COMPLETE=0
    fi
  fi
  

  if [[ "$line" == "detail: 37" ]]
  then
      if [[ $RECORDING_START -eq 0 ]]
      then
    #echo "Start recording..."
    RECORDING_START=$( date +%s%N | cut -b1-13 )
    
      else
    RECORDED_TRIGGER_EVENTS=$(($RECORDED_TRIGGER_EVENTS+1))
    #echo "got trigger during recording time total: $RECORDED_TRIGGER_EVENTS"
      fi
      
      if [[ $RECORDED_TRIGGER_EVENTS -gt $REQUIRED_TRIGGER_EVENT_AMOUNT ]]
      then
    #echo "TRIGGER COMPLETE: lets record next keystroke..."
    TRIGGER_COMPLETE=1
    
      fi
    

  fi
  if [[ $TRIGGER_COMPLETE -eq 1 ]] && [[ $line =~ detail\:\ ([[:digit:]]+) ]]
  then
    KEYCODE=${BASH_REMATCH[1]}
    #echo $KEYCODE
    if [[ "$KEYCODE" -eq "37" ]] || [[ "$KEYCODE" -eq "0" ]]
    then
      #echo "SSSS useless keycode $KEYCODE" 
      continue
    fi
    
    
    if [[ "$KEYCODE" -eq "28" ]]
    then
      echo "hardcoded 28"
      xdotool key "ctrl+t"
    fi
    
    if [[ "$KEYCODE" -eq "25" ]]
    then
      echo "hardcoded 25"
      xdotool key "ctrl+w"
    fi
    
    if [[ "$KEYCODE" -eq "45" ]]
    then
      echo "hardcoded 45"
      xdotool key "ctrl+k"
    fi
    
    if [[ "$KEYCODE" -eq "65" ]]
    then
      echo "hardcoded 65"
      xdotool key "ctrl+space"
    fi
    
    
    #echo "   XXXXXXXX recorded keycode: $KEYCODE"
    while IFS= read -r mapline
    do
      if [[ $mapline =~ ^keycode[[:space:]]+$KEYCODE[[:space:]] ]]
      then
    KEY_VALUE=$( echo $mapline | awk '{ print $4 }' )
    #echo "YYYYYEAH $mapline with keyvalue: $KEY_VALUE"
    if [[ $TRIGGER_COMPLETE -eq 1 ]]
    then
      echo "fire event ctrl+$KEY_VALUE with keycode $KEYCODE"
      xdotool key "ctrl+$KEY_VALUE"
      
      RECORDING_START=0
      RECORDED_TRIGGER_EVENTS=0
      TRIGGER_COMPLETE=0
      #sleep 1
    fi
    continue

      fi
    done < <( xmodmap -pke )
    
    
    
  fi
  
done
