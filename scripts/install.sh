#!/bin/sh

# Most of this script is shamelessly stolen from Pow's install script.
# Then again, the whole concept is shamelessly stolen as well.


# Fail fast if we're not on OS X >= 10.6.0.

    if [ "$(uname -s)" != "Darwin" ]; then
      echo "Sorry, Pow requires Mac OS X to run." >&2
      exit 1
    elif [ "$(expr "$(sw_vers -productVersion | cut -f 2 -d .)" \>= 6)" = 0 ]; then
      echo "Pow requires Mac OS X 10.6 or later." >&2
      exit 1
    fi


# Ask for some configuration variables

    printenv

    echo "##                            _   _                 "
    echo "##  _ __ ___   __ _ _ __ __ _| |_| |__   ___  _ __  "
    echo "## | '_ \` _ \ / _\` | '__/ _\` | __| '_ \ / _ \| '_ \ "
    echo "## | | | | | | (_| | | | (_| | |_| | | | (_) | | | |"
    echo "## |_| |_| |_|\__,_|_|  \__,_|\__|_| |_|\___/|_| |_|"
    echo "##"
    echo ""
    echo ""
    echo "Before we get started, I've just a couple quick questions."
    echo "The default answers are in parentheses - if you like what's"
    echo "there, just hit enter to move on!"
    echo ""


  # Configure project directory

    echo ""
    echo "Where would you like to link your projects from?"
    echo "(~/.marathon)  \c"

    read projects
    if [ -z "$projects" ]; then
      projects="~/.marathon"
    fi
    sed -i '' -e "s#PROJECTS#$projects#g" ./config.json


  # Configure log directory

    echo ""
    echo "Where do you want to keep logs?"
    echo "(~/.marathon/logs) \c"

    read logs
    if [ -z "$logs" ]; then
      logs="~/.marathon/logs"
    fi
    sed -i '' -e "s#LOGS#$logs#g" ./config.json


  # Configure tld for dns resolver

    echo ""
    echo "What tld do you want to access your apps at? (i.e. http://my-project.dev)?"
    echo "(dev) \c"

    read tld
    if [ -z "$tld" ]; then
      tld="dev"
    fi
    sed -i '' -e "s#TLD#$tld#g" ./config.json


  # Configure the edit command

    echo ""
    echo "What command do you use to open your editor?"
    echo "($EDITOR) \c"
    read editor

    if [ -z "$editor" ]; then
      editor=$EDITOR
    fi
    sed -i '' -e "s#EDITOR#$editor#g" ./config.json


# Configuration complete!

    echo ""
    echo "*** Configuration complete"

# Expand ~ in the configuration file

    echo ""
    echo "*** Expanding configuration paths ..."
    sed -i '' -e "s#~#$HOME#g" ./config.json
    logs=`echo $logs | sed s#~#$HOME#g`

# Install configuration files.


    echo "*** Installing configuration files..."
    sudo cp ./dns/resolver "/etc/resolver/$tld"
    sudo cp ./dns/davewasmer.marathon.forwarding.plist /Library/LaunchDaemons/
    cp ./web/davewasmer.marathon.marathond.plist "$HOME/Library/LaunchAgents/"
    modulepath=`pwd`
    execpath=$modulepath"/index.js"
    nodepath=$npm_config_prefix"/bin/node"
    # setup our launch daemon with the right paths
    sed -i '' -e "s#EXEC#$execpath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#NODE#$nodepath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#LOG#$logs/marathon.log#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#WORKINGDIR#$modulepath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#PATHEXPORT#$PATH#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"

    echo "*** Installing system configuration files as root..."
    sudo launchctl load -Fw /Library/LaunchDaemons/davewasmer.marathon.forwarding.plist 2>/dev/null
    launchctl load -Fw "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist" 2>/dev/null


# All done!

    echo "*** Installed"
    echo ""
    echo "Marathon is now installed. To get started, symlink your node"
    echo "projects into $projects, and check out http://marathon.$tld"
