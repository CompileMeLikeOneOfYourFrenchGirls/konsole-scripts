#!/bin/bash

display_help () {
  printf "Switch KOnsole PROfile\n"
  printf "This script switches the active profile for a KDE Konsole terminal between two hardcoded profiles.\n"
  printf "Supply no arguments to automatically get the PID of the active terminal window.\n"
  printf "Or supply a valid terminal window PID to change the profile of that specific window.\n"
  printf "\n"
  printf "This script is unable to select the active tab if the terminal window has multiple tabs,\n"
  printf "it will always change the profile of the first tab, unless a tab number will be specified as the last argument to the script.\n"
  printf "In that case, it will try to change that tab profile. It will fail if that number does not correspond to a valid tab session.\n"
  printf "\n"
  printf "Working:\n"
  printf "\n"
  printf "We get the window process using: \n"
  printf "xprop -id \$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d\" \" -f2) | grep PID\n"
  printf "\n"
  printf "Then we use the process number as argument for:\n"
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

  result="$(qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" profile)"

  while [[ "$result" == *"Error"* ]]; do

    ((++tabsession))
    result="$(qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" profile)"

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

    current_profile="$(qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" profile)"

    #If the qdbus command returns an Error, most likely the tab number is incorrect
    #We increase the number until we find a valid tab session, or break the loop if we reach 20


    if [[ $current_profile == "starship" ]] ; then
      newprofile="$(printf 'starship light')" ; else
      newprofile="$(printf 'starship')"
    fi

    printf "Switching to profile: %s\n" "$newprofile"
    qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" setProfile "$newprofile"
    #printf "result: $?\n"
    exit 0
  fi

  printf "Switching to profile: %s\n" "$profile"
  qdbus org.kde.konsole-"$pid" /Sessions/"$tabsession" setProfile "$profile"
  #printf "result: $?\n"
  exit 0
}

get_terminal_pid () {

  # This gets the PID of the current (active) window
  local xdpyinfo_string
  local pidstring
  xdpyinfo_string="$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2)"
  pidstring="$(xprop -id "$xdpyinfo_string" | grep PID)"
  pid="${pidstring//[^[:digit:]]/}"
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

  #files is an array containing the full path of every file ending in .profile
  #we only need the filename without the extension
  for file in "${files[@]}"; do
    # Note that we need a temporary variable inside this block to correctly perform substitution before adding to array
    # file##*/ removes the path from the file string
    #filename="${file##*/}"
    #alternatively, use basename
    filename=$(basename "$file")
    # filename%.profile removes the last occurrence of .profile from the file name
    file="${filename%.profile}"
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
  for array_pid in "${pslist[@]}"; do
    if [[ "$array_pid" == "$1" ]]; then
      printf "Correct PID value passed!"
      pid="$1"
      return
    fi
  done

  printf "Error, wrong PID number, falling back to this terminal emulator PID\n"
  printf "\n"
  get_terminal_pid
  printf "PID value is: %s\n" "$pid"

}

LC_COLLATE=C
tabsession=""
profile=""

main () {

  local rest
  local arg1="$1"; shift
  local arg2="$1"; shift
  local arg3="$1"; shift

  rest=$(IFS=, ; echo "$*")
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
    if [[ "$arg3" =~ ^[0-9]$ ]]; then

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

    if [[ "$arg2" =~ ^[0-9]$ ]]; then

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

    elif [[ "$arg1" == "-l" ]]; then

      list_profiles
      printf "Available profiles:\n"
      printf "%s\n" "${filelist[@]}"
      exit 0

    elif [[ "$arg1" =~ ^[0-9]+$ ]]; then

      pid="$arg1"
      check_pid "$pid"

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
    printf "PID value is: %s\n" "$pid"
  fi


  switch_konsole_profile
}

#xdpyinfo_string=$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2)
#printf $xdpyinfo_string

#xprop_string=`xprop -id \`xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d" " -f2\` | grep PID`
#printf $xprop_string


main "$@"
