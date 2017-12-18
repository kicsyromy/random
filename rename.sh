#!/bin/bash

printerror() { cat <<< "$@" 1>&2; }

USAGE=$(printf "\nUsage:\n$0 -t|--show-name \"The Flash 2014\" -s|--season 3 [-e|--episode-interval 2-14] [-b|--handle-subtitles] [-l|--subtitle-language en]\n\n")
ARGS=$(getopt -o :t:s:e:bl: --long show-name:,season:,episode-interval:,handle-subtitles,subtitle-language: -- "$@")

if [ $? != 0 ] ; then
    printerror "$USAGE"
    exit 1
fi

eval set -- "$ARGS"
while true ; do
    case $1 in
        -t|--show-name)
            SHOW_NAME=$2 ; shift 2 ;;
        -s|--season)
            SEASON=$2 ; shift 2 ;;
        -e|--episode-interval)
            EPISODE_INTERVAL="$2" ; shift 2 ;;
        -b|--handle-subtitles)
            HANDLE_SUBTITLES=1 ; shift ;;
        -l|--subtitle-language)
            SUBTITLE_LANGUAGE="$2" ; shift 2 ;;
        --)
            shift ; break ;;
    esac
done

if [ -z "$SHOW_NAME" ]; then
    printerror "-t|--show-name is a mandatory parameter"
    printerror "$USAGE"
    exit 1
fi

if [ -n "$SEASON" ]; then
    SEASON=$(echo $SEASON | grep -o "^[0-9]*")
    if [ -z "$SEASON" ]; then
        printerror "Invalid season number"
        printerror "$USAGE"
        exit 1
    fi
else
    printerror "-s|--season is a mandatory parameter"
    printerror "$USAGE"
    exit 1
fi

echo "Show name: $SHOW_NAME"
echo "Season: $SEASON"

if (( "$SEASON" < 10 )) ; then
    SEASON="0$SEASON"
fi

if [ -n "$EPISODE_INTERVAL" ]; then
    HAS_SEPARATOR=$(echo $EPISODE_INTERVAL | grep -aob '-')
    if [ ! -z "$HAS_SEPARATOR" ]; then
        EPISODE_START=$(echo $EPISODE_INTERVAL | cut -d'-' -f1)
        EPISODE_END=$(echo $EPISODE_INTERVAL | cut -d'-' -f2)
        echo "Assuming the files start at episode $EPISODE_START and end at $EPISODE_END"
    else
        echo "Given episode interval was not understood"
        exit 1
    fi
else
    echo "No episode interval was given, assuming episode count starts from first episode of the season and continues for the total number of files"
    EPISODE_START=1
    unset EPISODE_END
fi

if [ -n "$HANDLE_SUBTITLES" ]; then
    if [ -z "$SUBTITLE_LANGUAGE" ]; then
        SUBTITLE_LANGUAGE=en
    fi
    SUB_EXTENSIONS=".srt$|.idx$|.sub$"
fi

FILE_NAMES=file_names
EPISODE_NAMES=episode_names
SHOW_NAME_LOWER=$(echo $SHOW_NAME | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
URL="http://www.tv.com/shows/$SHOW_NAME_LOWER/season-$SEASON"

ls --format=single-column | grep -E ".mkv$|.avi$|.mp4$|.mpeg$|.mpg$|.divx$" > $FILE_NAMES
wget --quiet -O - $URL | grep "title\"href=\"" | cut -f2 -d'>' | cut -f1 -d'<' | tac | tr '[/]' '[\-]'| sed 's/:/ -/g' > $EPISODE_NAMES

EPISODE_COUNTER=$EPISODE_START
while read EPISODE_FILE; do
    EXTENSION=$(echo $EPISODE_FILE | rev | cut -f1 -d'.' | rev)
    if (( "$EPISODE_COUNTER" < 10 )) ; then
        echo "Video file: Rename $EPISODE_FILE to $SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        if [ -z "$DRY_RUN" ]; then
            mv "$EPISODE_FILE" "$SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        fi  

        if [ -n "$HANDLE_SUBTITLES" ]; then
            BASENAME=$(echo $EPISODE_FILE | rev | cut -f2- -d'.' | rev)
            SUBTITLES=$(ls $BASENAME* --format=single-column | grep -E "$SUB_EXTENSIONS")
            for SUBTITLE_FILE in $SUBTITLES; do
                SUB_EXTENSION=$(echo $SUBTITLE_FILE | rev | cut -f1 -d'.' | rev)
                echo "Subtitle: Rename $SUBTITLE_FILE to $SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${SUBTITLE_LANGUAGE}.${SUB_EXTENSION}"

                if [ -z "$DRY_RUN" ]; then
                    mv "$SUBTITLE_FILE" "$SHOW_NAME - s${SEASON}e0${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${SUBTITLE_LANGUAGE}.${SUB_EXTENSION}"
                fi  
            done
        fi
    else
        echo "Video file: Rename $EPISODE_FILE to $SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        if [ -z "$DRY_RUN" ]; then
            mv "$EPISODE_FILE" "$SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${EXTENSION}"
        fi  

        if [ -n "$HANDLE_SUBTITLES" ]; then
            BASENAME=$(echo $EPISODE_FILE | rev | cut -f2- -d'.' | rev)
            SUBTITLES=$(ls $BASENAME* --format=single-column | grep -E "$SUB_EXTENSIONS")
            for SUBTITLE_FILE in $SUBTITLES; do
                SUB_EXTENSION=$(echo $SUBTITLE_FILE | rev | cut -f1 -d'.' | rev)
                echo "Subtitle: Rename $SUBTITLE_FILE to $SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${SUBTITLE_LANGUAGE}.${SUB_EXTENSION}"

                if [ -z "$DRY_RUN" ]; then
                    mv "$SUBTITLE_FILE" "$SHOW_NAME - s${SEASON}e${EPISODE_COUNTER} - $(sed -n ${EPISODE_COUNTER}p $EPISODE_NAMES).${SUBTITLE_LANGUAGE}.${SUB_EXTENSION}"
                fi  
            done
        fi
    fi

    EPISODE_COUNTER=$[EPISODE_COUNTER + 1]

    if [ -n "$EPISODE_END" ]; then
        if (( "$EPISODE_COUNTER" > "$EPISODE_END" )) ; then
            break
        fi
    fi
done < $FILE_NAMES

rm $FILE_NAMES
rm $EPISODE_NAMES
