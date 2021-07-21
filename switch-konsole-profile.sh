#!/bin/bash

display_help () {
  printf "Usage: ./switch-konsole-profile.sh [options] [arguments]\n"
  printf "Where arguments can be one or more of the following:\n"
  printf "\n"
  printf "Process ID of konsole (terminal emulator) window.\n"
  printf "Profile name to switch to.\n"
  printf "Tab session number in case of multiple tabs.\n"
  printf "\n"
  printf "Options are: \n"
  printf "To show available profiles: -l\n"
  printf "To show this help: -h\n"
  printf "To show full help: --help\n"
  exit 0
}
display_help_full () {
  printf "Usage: ./switch-konsole-profile.sh [options] [arguments]\n"
  printf "Where arguments can be one or more of the following:\n"
  printf "\n"
  printf "Process ID of konsole (terminal emulator) window.\n"
  printf "Profile name to switch to.\n"
  printf "Tab session number in case of multiple tabs.\n"
  printf "\n"
  printf "Options are: \n"
  printf "To show available profiles: -l\n"
  printf "To show this help: -h\n"
  printf "To show full help: --help\n"
  printf "\n"
  printf "This script switches the active profile for a KDE Konsole terminal to a specified profile,\n"
  printf "or if missing, between two hardcoded profiles.\n"
  printf "It is able to retrieve the PID of the active terminal window automatically, and MAY be able to guess the correct\n"
  printf "tab session in case of multiple tabs open in the same window.\n"
  printf "\n"
  printf "Is it also possible to supply a valid terminal window PID to change the profile of that specific window.\n"
  printf "If no tab number is passed to the script,  it will try to change the profile of the first tab.\n"
  printf "\n"
  printf "We get the window process using:\n"
  printf "\n"
  printf "xprop -id \$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d\" \" -f2) | grep PID\n"
  printf "\n"
  printf "Then we use the process number as argument for:\n"
  printf "\n"
  printf "qdbus org.kde.konsole-PID /Sessions/1 profile\n"
  printf "\n"
  printf "to retrieve the current profile, and to:\n"
  printf "\n"
  printf "qdbus org.kde.konsole-PID /Sessions/1 setProfile\n"
  printf "\n"
  printf "to set the new profile.\n"
  exit 0
}

get_valid_tab () {

  if [[ -z "$tabsession" ]]; then

    tabsession=1
  fi

  result="$(qdbus org.kde.konsole-$pid /Sessions/"$tabsession" profile)"

  while [[ "$result" == *"Error"* ]]; do

    ((++tabsession))
    result="$(qdbus org.kde.konsole-$pid /Sessions/"$tabsession" profile)"

    if [[ "$tabsession" -gt 20 ]]; then
      printf "Error while searching for a valid tab session\n"
      printf "No valid session found with value under 20\n"
      exit 1
    fi

  done
}

switch_konsole_profile () {

  get_valid_tab

  if [[ -z "$profile" ]] ; then

    current_profile="$(qdbus org.kde.konsole-$pid /Sessions/"$tabsession" profile)"

    #If the qdbus command returns an Error, most likely the tab number is incorrect
    #We increase the number until we find a valid tab session, or break the loop if we reach 20

    
    if [[ $current_profile == "starship" ]] ; then
      newprofile="$(printf 'starship light')" ; else
      newprofile="$(printf 'starship')"
    fi
    
    printf "Switching to profile: $newprofile\n"
    qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" setProfile "$newprofile"
    #printf "result: $?\n"
    exit 0
  fi

  printf "Switching to profile: $profile\n"
  qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" setProfile "$profile"
  #printf "result: $?\n"
  exit 0
}

get_terminal_pid () {

  # This gets the PID of the current (active) window
  local xdpyinfo_string="$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2)"
  local pidstring="$(xprop -id $xdpyinfo_string | grep PID)"
  pid="$( echo ${pidstring//[^[:digit:]]/})"
  #printf "pid value is:\n"
  #printf "$pid\n"

  if [[ -z "$pid" ]] ; then
    exit 1
  fi
}

list_profiles () {

  shopt -s nullglob
  source_dir=$HOME/.local/share/konsole
  files=("$source_dir"/*.profile)

  for file in "${files[@]}"; do
    y="${file##*/}"
    file="${y%.profile}"
    filelist=("${filelist[@]}" "$file")
  done
}

confirm_profile () {
  
  list_profiles

  for f in "${filelist[@]}"
  do

    if [[ "$requested_profile" == "$f" ]]; then

      profile="$f"
      break
    fi
  done
}

check_pid () {

  pslist=$(pgrep -lf /usr/bin/konsole)
  
  echo "$pslist" | grep -q "$pid"

  if ! [[ "$?" = "0" ]]; then

    printf "Error, wrong PID number, falling back to this terminal emulator PID\n"
    printf "\n"
    get_terminal_pid
    printf "PID value is: $pid\n"
  fi

}

LC_COLLATE=C
tabsession=""
profile=""

main () {

  local arg1="$1"; shift
  local arg2="$1"; shift
  local arg3="$1"; shift
  local rest="$@"
  declare -a filelist
  declare -a files

  if [[ -n "$rest" ]] ; then
    printf "Too many arguments!\n"
    printf "Remember to use quotes if your profile name has a space in it.\n"
    printf "Use -h to display some help.\n"
    exit 0
  fi


  if [[ -n "$arg3" ]]; then
    
    # this returns 0 (false) if left side matches right side
    # or 1 (true) otherwise 
    if [[ "$arg3" == "-h" ]]; then

      display_help

    elif [[ "$arg3" == "--help" ]]; then

      display_help_full

    elif [[ "$arg3" == "-l" ]]; then

      list_profiles
      printf "\n"
      printf "$filelist\n"
      exit 0

    elif [[ "$arg3" =~ ^[0-9]$ ]]; then

      tabsession="$arg3"

    elif [[ "$arg3" =~ ^[0-9]+$ ]]; then

      pid="$arg3"
      check_pid

      
    else

      #not a number, so treat it as a profile name
      requested_profile="$arg3"
      confirm_profile

      if [[ -z "$profile" ]]; then


        if ! [[ "$arg2" =~ ^[0-9]+$ ]]; then

          requested_profile="$arg2 $arg3"
          confirm_profile

          if [[ -z "$profile" ]]; then

            printf "Error, wrong profile specified.\n"
            printf "Remember to use quotes if your profile name has a space in it.\n"
            printf "Use -l to list available profiles.\n"
            exit 0
          fi

          arg2=""


        else

          printf "Error, wrong profile specified.\n"
          printf "Remember to use quotes if your profile name has a space in it.\n"
          printf "Use -l to list available profiles.\n"
          exit 0


        fi
      fi
    fi
  fi

  if [[ -n "$arg2" ]]; then

    if [[ "$arg2" == "-h" ]]; then

      display_help

    elif [[ "$arg2" == "--help" ]]; then

      display_help_full

    elif [[ "$arg2" == "-l" ]]; then

      list_profiles
      printf "\n"
      printf "$filelist\n"
      exit 0

    elif [[ "$arg2" =~ ^[0-9]$ ]]; then

      tabsession="$arg2"

    elif [[ "$arg2" =~ ^[0-9]+$ ]]; then

      pid="$arg2"
      check_pid

    else

      #not a number, so treat it as a profile name
      requested_profile="$arg2"
      confirm_profile

      if [[ -z "$profile" ]]; then

        if ! [[ "$arg1" =~ ^[0-9]+$ ]]; then

          requested_profile="$arg1 $arg2"
          confirm_profile

          if [[ -z "$profile" ]]; then

            printf "Error, wrong profile specified.\n"
            printf "Remember to use quotes if your profile name has a space in it.\n"
            printf "Use -l to list available profiles.\n"
            exit 0
          fi

          arg1=""


        else

          printf "Error, wrong profile specified.\n"
          printf "Remember to use quotes if your profile name has a space in it.\n"
          printf "Use -l to list available profiles.\n"
          exit 0

        fi
      fi
    fi
  fi

  if [[ -n "$arg1" ]]; then

    if [[ "$arg1" =~ ^[0-9]$ ]]; then

      tabsession="$arg1"

    elif [[ "$arg1" == "-h" ]]; then

      display_help

    elif [[ "$arg1" == "--help" ]]; then

      display_help_full

    elif [[ "$arg1" == "-l" ]]; then

      list_profiles
      printf "\n"
      printf "$filelist\n"
      exit 0

    elif [[ "$arg1" =~ ^[0-9]+$ ]]; then

      pid="$arg1"
      check_pid

    else

      #not a number, so treat it as a profile name
      requested_profile="$arg1"
      confirm_profile

      if [[ -z "$profile" ]]; then

        printf "Error, wrong profile specified.\n"
        printf "Use -l to list available profiles.\n"
        exit 0
      fi
    fi
  fi


  if [[ -z "$pid" ]]; then

    get_terminal_pid
    printf "PID value is: $pid\n"
  fi
  
  
  switch_konsole_profile
}

#xdpyinfo_string=$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2)
#printf $xdpyinfo_string

#xprop_string=`xprop -id \`xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2\` | grep PID`
#printf $xprop_string


main "$@"
