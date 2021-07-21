# switch-konsole-profile

This script switches the active profile for a KDE Konsole terminal to a specified profile,
or if missing, between two hardcoded profiles.
It is able to retrieve the PID of the active terminal window automatically, and MAY be able to guess the correct
tab session in case of multiple tabs open in the same window.

Is it also possible to supply a valid terminal window PID to change the profile of that specific window.
If no tab number is passed to the script,  it will try to change the profile of the first tab.

We get the window process using:

`xprop -id \$(xdpyinfo | grep -Eo 'window 0x[^,]+' | cut -d\" \" -f2) | grep PID`

Then we use the process number as argument for:

`qdbus org.kde.konsole-PID /Sessions/1 profile`

to retrieve the current profile, and to:

`qdbus org.kde.konsole-PID /Sessions/1 setProfile`

to set the new profile.

### Usage:

`./switch-konsole-profile.sh [options] [arguments]`

Where arguments can be one or more of the following:

Process ID of konsole (terminal emulator) window.
Profile name to switch to.
Tab session number in case of multiple tabs.

Options are: 
To show available profiles: -l
To show this help: -h
To show full help: --help


# set-konsole-tab-name

For now it's just a copy of [this stackoverflow answer](https://stackoverflow.com/a/67161999)
