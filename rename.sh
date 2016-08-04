#!/bin/bash

if [ -z "$1" ]; then
    echo "Show name must the first argument"
    exit 1
fi

SHOW_NAME=$1
echo "Show name: $SHOW_NAME"

if [ -n "$2" ]; then
    SEASON=$(echo $2 | grep -E "^[0-9]")
    if [ -z "$SEASON" ]; then
        echo "Invalid season number"
        exit 1
    fi
else
    echo "Season number must be the second argument"
    exit 1
fi

echo "Season: $SEASON"

FILE_NAMES=file_names
EPISODE_NAMES=episode_names
SHOW_NAME_LOWER=$(echo $SHOW_NAME | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
URL="http://www.tv.com/shows/$SHOW_NAME_LOWER/season-$SEASON"

ls --format=single-column | grep -E ".mkv$|.avi$|.mp4$|.mpeg$|.mpg$|.divx$" > $FILE_NAMES
wget --quiet -O - $URL | grep "title\"href=\"" | cut -f2 -d'>' | cut -f1 -d'<' | tac > $EPISODE_NAMES

if (( "$SEASON" < 10 )) ; then
    SEASON="0$SEASON"
fi

EPISODE_COUNTER=1
while read EPISODE_FILE; do
    EXTENSION=$(echo $EPISODE_FILE | rev | cut -f1 -d'.' | rev)
    if (( "$EPISODE_COUNTER" < 10 )) ; then
        echo "Rename $EPISODE_FILE to $SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        if [ -z "$DRY_RUN" ]; then
            mv "$EPISODE_FILE" "$SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        fi  
    else
        echo "Rename $EPISODE_FILE to $SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        if [ -z "$DRY_RUN" ]; then
            mv "$EPISODE_FILE" "$SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        fi  
    fi
    EPISODE_COUNTER=$[EPISODE_COUNTER + 1]
done < $FILE_NAMES

rm $FILE_NAMES
rm $EPISODE_NAMES

