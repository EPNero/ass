#!/bin/bash

# File options
IMAGEPATH="$HOME/Pictures/" # Where to store screenshots before they are deleted
IMAGENAME="ass" # Not really important, tells this script which image to send and delete
FILE="$IMAGEPATH$IMAGENAME" # for future convenience, please do not edit

# Authentication
# if left empty, the script will still work but the screenshot will be copied to your clipboard instead of being uploaded to ass
KEY=""
DOMAIN=""

# helper function to take flameshot screenshots
takeFlameshot(){
    flameshot config -f "$IMAGENAME" # Make sure that Flameshot names the file correctly
	flameshot gui -r -p "$IMAGEPATH" > /dev/null # Prompt the screenshot GUI, also append the random gibberish to /dev/null
}

# helper function to take screenshots on wayland using grim + slurp for region capture
takeGrimshot(){
    grim -g "$(slurp)" "${FILE}.png" > /dev/null # attempt to mute grim, not sure if it's necessary
}


# decide on the tool based on display backend
if [[ "${XDG_SESSION_TYPE}" == x11 ]]; then
	takeFlameshot
fi

if [[ "${XDG_SESSION_TYPE}" == wayland ]]; then
    takeGrimshot 
else
	echo -en "Unknown display backend.\n Falling back to X11 (Flameshot)..."
	takeFlameshot > ./Flameshot.log
	echo -en "Done. Make sure you check for errors.\nLogfile located in the same directory as this script."
fi

# check if the screenshot file actually exists before proceeding
if [[ -f "${FILE}" ]]; then
    # check if KEY and DOMAIN are correct,
    # if they are, upload the file to the ass instance
    # if not, copy the image to clipboard and exit
    if [[ ( -z ${KEY+x} && -v ${DOMAIN+x} ) ]]; then
        URL=$(curl -X POST \
            -H "Content-Type: multipart/form-data" \
            -H "Accept: application/json" \
            -H "User-Agent: ShareX/13.4.0" \
            -H "Authorization: $KEY" \
            -H "X-Ass-OG-Provider: wasting my server storage" \
            -H "X-Ass-OG-Title: this shit took &size" \
            -H "X-Ass-OG-Color: &vibrant" \
            -F "file=@$FILE" "https://$DOMAIN/" | grep -Po '(?<="resource":")[^"]+')
        if [[ "${XDG_SESSION_TYPE}" == x11 ]]; then
            # printf instead of echo as echo appends a newline
            printf "%s" "$URL" | xclip -sel clip # it is safe to use xclip on xorg, so we don't need wl-copy
        fi
        if [[ "${XDG_SESSION_TYPE}" == wayland ]]; then
            # if desktop session is wayland instead of xclip, use wl-copy
            printf "%s" "$URL" | wl-copy
        else
            printf "%s" Invalid desktop session!
        fi
        rm "${FILE}" # Delete the image locally
        exit 1
    else
        # If domain & key are not set, assume it is a local screenshot and copy the image directly to clipboard
        if [[ "${XDG_SESSION_TYPE}" == x11 ]]; then # if x11, use xclip
            # TODO: find a way to copy image to clipboard on qt environments like plasma
            echo "WIP"
        fi
        if [[ "${XDG_SESSION_TYPE}" == wayland ]]; then # if wayland, use wl-clipboard
            wl-copy < $FILE
            exit 1
        else
            echo -en "Unknown display backend.\n Falling back to X11 (xclip)..."
            #TODO: find a way to copy image to clipboard on qt environments like plasma
            exit 1p
        fi
    fi
else
    # Abort screenshot if $FILE does not exist
    echo "Screenshot aborted."
fi

