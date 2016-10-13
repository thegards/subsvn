#!/usr/bin/bash

CURRENT=`svn info | grep "Relative" | sed 's/Relative URL: //g'`
BRANCH_FOLDER="branches"
BRANCH_PREFIX="$BRANCH_FOLDER/"
BRANCH_MARKER="/$BRANCH_FOLDER/"

TAG_FOLDER="tags"
TAG_PREFIX="$TAG_FOLDER/"
TAG_MARKER="/$TAG_FOLDER/"

IS_BRANCH=`echo "$CURRENT" | grep $BRANCH_MARKER &>/dev/null && echo 'true' || echo 'false'`
IS_TAG=`echo "$CURRENT" | grep $TAG_MARKER &>/dev/null && echo 'true' || echo 'false'`

test "x$V" = "x1" && echo "IS_BRANCH="$IS_BRANCH
test "x$V" = "x1" && echo "IS_TAG="$IS_TAG
if [ "x$IS_BRANCH" = "xtrue" ]
then
    ROOT=${CURRENT%%$BRANCH_MARKER*}
    CURRENT_NAME=${CURRENT##*$BRANCH_MARKER}
    CURRENT_PATH=$BRANCH_MARKER$CURRENT_NAME
elif [ "x$IS_TAG" = "xtrue" ]
then
    ROOT=${CURRENT%%$TAG_MARKER*}
    CURRENT_NAME=${CURRENT##*$TAG_MARKER}
    CURRENT_PATH=$TAG_MARKER$CURRENT_NAME
else
    ROOT=${CURRENT%%"/trunk"}
    CURRENT_NAME="trunk"
    CURRENT_PATH="/trunk"
fi

test "x$V" = "x1" && echo "ROOT="$ROOT
test "x$V" = "x1" && echo "CURRENT_NAME="$CURRENT_NAME
test "x$V" = "x1" && echo "CURRENT_PATH="$CURRENT_PATH
test "x$V" = "x1" && echo "Currently on "$CURRENT

COMMAND=$1
shift

case $COMMAND in
    log|merge)
        SOURCE=$1
        shift

        if [ "x$SOURCE" = "xtrunk" ]
        then
            SOURCE_PATH="/trunk"
        else
            SOURCE_PATH=$BRANCH_MARKER$SOURCE
        fi

        svn $COMMAND $ROOT$SOURCE_PATH $1 $2 $3 $4 $5 $6 $7 $8 $9
    ;;
    branch)
        BRANCH_NAME=$1
        echo "Creating branch $BRANCH_NAME from $CURRENT_NAME"
        svn cp $CURRENT $ROOT$BRANCH_MARKER$BRANCH_NAME

        echo "Switching working copy to branch $BRANCH_NAME"
        svn sw $ROOT$BRANCH_MARKER$BRANCH_NAME
    ;;
    tag)
        TAG_NAME=$1
        echo "Creating tag $TAG_NAME from $CURRENT_NAME"
        svn cp $CURRENT $ROOT$TAG_MARKER$TAG_NAME
    ;;
    sw|switch)
        BRANCH_NAME=$1
        if [ "x$BRANCH_NAME" = "xtrunk" ]
        then
            echo "Switching working copy to $BRANCH_NAME"
            svn sw $ROOT"/"$BRANCH_NAME
        else
            echo "Switching working copy to branch $BRANCH_NAME"
            svn sw $ROOT$BRANCH_MARKER$BRANCH_NAME
        fi
    ;;
    switch_to_*|sw_to_*)
        TARGET_TYPE=${COMMAND##sw*_to_}
        case $TARGET_TYPE in
            trunk)
                TARGET="/trunk"
            ;;
            branch)
                TARGET=$BRANCH_MARKER$1
            ;;
            tag)
                TARGET=$TAG_MARKER$1
            ;;
            *)
                echo "Unknown target type $TARGET_TYPE"
                exit 1
            ;;
        esac
        echo "Switching to "$ROOT$TARGET
        svn sw $ROOT$TARGET
    ;;
    *_from_*)
        SOURCE_NAME=$1
        TARGET_NAME=$2

        OPERATION=${COMMAND%%_from_*}
        SOURCE_TYPE=${COMMAND##*_from_}
        echo "OPERATION="$OPERATION
        echo "SOURCE="$SOURCE
        case $OPERATION in
            branch)
                TARGET_PATH=$BRANCH_MARKER$TARGET_NAME
            ;;
            tag)
                TARGET_PATH=$TAG_MARKER$TARGET_NAME
            ;;
            *)
                echo "Unknown operation "$OPERATION
                exit 1
            ;;
        esac
        case $SOURCE_TYPE in
            trunk)
                SOURCE_PATH="/trunk"
            ;;
            branch)
                SOURCE_PATH=$BRANCH_MARKER$SOURCE_NAME
            ;;
            tag)
                SOURCE_PATH=$TAG_MARKER$SOURCE_NAME
            ;;
            *)
                echo "Unknown source "$SOURCE_TYPE
                exit 1
            ;;
        esac
        echo "Creating $OPERATION with name $TARGET_NAME"
        svn cp $ROOT$SOURCE_PATH $ROOT$TARGET_PATH

        if [ "x$OPERATION" = "xbranch" ]
        then
            echo "Switching working copy to $OPERATION $TARGET_NAME"
            svn sw $ROOT$TARGET_PATH
        fi
    ;;
    ls-*)
        SOURCE=${COMMAND##ls-}
        case $SOURCE in
            branch)
                TARGET_DIR=$BRANCH_MARKER
            ;;
            tag)
                TARGET_DIR=$TAG_MARKER
            ;;
            *)
                echo "Unknown operation ls-$SOURCE"
                exit 1
            ;;
        esac
        svn ls $ROOT$TARGET_DIR
    ;;
    pristine)
        echo "WARNING: THIS WILL REVERT ALL CHANGES AND REMOVE UNVERSIONED AND IGNORED FILES FROM YOUR WORKING COPY."
        echo "Press [enter] to proceed or ^C [Control-C] to abort."
        read

        echo "Reverting modifications..."
        svn revert -R .
        echo "Removing unversioned and ignored files..."
        svn st --no-ignore | cut -c 9- | sed 's/\\/\//g' | xargs -I{} rm -rf "{}"
    ;;
    *)
        if [ "x$COMMAND" != "xhelp" ]
        then
            echo "Unknown command \"$COMMAND\""
        fi
        echo "Usage: "
        echo $0" command args"
        echo ""
        echo "Available commands:"
        echo " log                  )   Prints history information for a given branch or trunk."
        echo "                          Accepts target branch name or trunk as argument."
        echo "                          All arguments after the branch name are passed to the svn log command."
        echo " merge                )   Merges a given branch or trunk into the working copy."
        echo "                          Accepts target branch name or trunk as argument."
        echo "                          All arguments after the branch name are passed to the svn merge command."
        echo " branch               )   Create branch from current working copy path and switch to it."
        echo "                          Accepts target branch name as argument."
        echo " tag                  )   Create tag from current working copy path."
        echo "                          Accepts target tag name as argument."
        echo " tag_from_tag         )   Create new tag from target tag."
        echo "                          Accepts target tag as FIRST argument and new tag name as SECOND argument."
        echo " tag_from_branch      )   Create new tag from target branch."
        echo "                          Accepts target branch as FIRST argument and new tag name as SECOND argument."
        echo " tag_from_trunk       )   Create new tag from trunk."
        echo "                          Accepts new tag name as argument."
        echo " branch_from_tag      )   Create new branch from target tag and switch to it."
        echo "                          Accepts target tag as FIRST argument and new branch name as SECOND argument."
        echo " branch_from_branch   )   Create new branch from target branch and switch to it."
        echo "                          Accepts target branch as FIRST argument and new branch name as SECOND argument."
        echo " branch_from_trunk    )   Create new branch from trunk and switch to it."
        echo "                          Accepts new branch name as argument."
        echo " sw|switch            )   Switch working copy to target branch or trunk."
        echo "                          Accepts target branch name or trunk as argument."
        echo " sw_to_branch             "
        echo " switch_to_branch     )   Switch working copy to target branch."
        echo "                          Accepts target branch name as argument."
        echo " sw_to_tag                "
        echo " switch_to_tag        )   Switch working copy to target tag."
        echo "                          Accepts target tag name as argument."
        echo " sw_to_trunk              "
        echo " switch_to_trunk      )   Switch working copy to repository trunk."
        echo " pristine             )   Thoroughly cleans the working copy, reverting all changes"
        echo "                          and removing all unversioned and ignored files."
        echo " ls-branch            )   Lists all branches in the repository."
        echo " ls-tag               )   Lists all tags in the repository."
    ;;
esac
