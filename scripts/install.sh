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

    echo "*** Configuring Marathon ..."

    echo -n "Where are your projects? (~/.marathon) "
    read projects
    if [ -n "$projects" ]; then
      sed -i "s/PROJECTS/$projects/g" config.json
    else
      sed -i "s/PROJECTS/~\/.marathon/g" config.json
    fi

    echo -n "Where do you want the logs? (~/.marathon/logs) "
    read logs
    if [ -n "$logs" ]; then
      sed -i "s/LOGS/$logs/g" config.json
    else
      sed -i "s/LOGS/~\/.marathon\/logs/g" config.json
    fi

    echo -n "What tld (i.e. http://my-project.dev)? (dev) "
    read tld
    if [ -n "$tld" ]; then
      sed -i "s/TLD/$tld/g" config.json
    else
      tld = "dev"
      sed -i "s/TLD/dev/g" config.json
    fi

    echo -n "What is your editor command? ($EDITOR) "
    read editor
    if [ -n "$editor" ]; then
      sed -i "s/EDITOR/$editor/g" config.json
    else
      sed -i "s/EDITOR/$EDITOR/g" config.json
    fi

    sed -i "s/~/$HOME/g" config.json


# Install configuration files.

    echo "*** Installing configuration files..."
    cp ./dns/resolver "/etc/resolver/$tld"
    cp ./dns/davewasmer.marathon.forwarding.plist /Library/LaunchDaemons/
    cp ./web/davewasmer.marathon.marathond.plist "$HOME/Library/LaunchAgents/"

    echo "*** Installing system configuration files as root..."
    sudo launchctl load -Fw /Library/LaunchDaemons/davewasmer.marathon.forwarding.plist 2>/dev/null
    launchctl load -Fw "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist" 2>/dev/null


# All done!

    echo "*** Installed"
    print_troubleshooting_instructions
