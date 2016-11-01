#!/bin/bash
SUBSVN_CMD=${SUBSVN_CMD:-svn}

CURRENT=`$SUBSVN_CMD info | grep "Relative" | sed 's/Relative URL: //g'`
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
    diff|status|st|info|cleanup|revert|resolve)
        $SUBSVN_CMD $COMMAND $1 $2 $3 $4 $5 $6 $7 $8 $9
    ;;
    log|merge)
        SOURCE=$1
        shift

        if [ "x$SOURCE" = "xtrunk" ]
        then
            SOURCE_PATH="/trunk"
        else
            SOURCE_PATH=$BRANCH_MARKER$SOURCE
        fi

        $SUBSVN_CMD $COMMAND $ROOT$SOURCE_PATH $1 $2 $3 $4 $5 $6 $7 $8 $9
    ;;
    branch)
        BRANCH_NAME=$1
        echo "Creating branch $BRANCH_NAME from $CURRENT_NAME"
        $SUBSVN_CMD cp $CURRENT $ROOT$BRANCH_MARKER$BRANCH_NAME

        echo "Switching working copy to branch $BRANCH_NAME"
        $SUBSVN_CMD sw $ROOT$BRANCH_MARKER$BRANCH_NAME
    ;;
    tag)
        TAG_NAME=$1
        echo "Creating tag $TAG_NAME from $CURRENT_NAME"
        $SUBSVN_CMD cp $CURRENT $ROOT$TAG_MARKER$TAG_NAME
    ;;
    sw|switch)
        BRANCH_NAME=$1
        if [ "x$BRANCH_NAME" = "xtrunk" ]
        then
            echo "Switching working copy to $BRANCH_NAME"
            $SUBSVN_CMD sw $ROOT"/"$BRANCH_NAME
        else
            echo "Switching working copy to branch $BRANCH_NAME"
            $SUBSVN_CMD sw $ROOT$BRANCH_MARKER$BRANCH_NAME
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
        $SUBSVN_CMD sw $ROOT$TARGET
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
        $SUBSVN_CMD ls $ROOT$TARGET_DIR
    ;;
    pristine)
        echo "WARNING: THIS WILL REVERT ALL CHANGES AND REMOVE UNVERSIONED AND IGNORED FILES FROM YOUR WORKING COPY."
        echo "Press [enter] to proceed or ^C [Control-C] to abort."
        read

        echo "Reverting modifications..."
        $SUBSVN_CMD revert -R .
        echo "Removing unversioned and ignored files..."
        $SUBSVN_CMD st --no-ignore | cut -c 9- | sed 's/\\/\//g' | xargs -I{} rm -rf "{}"
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
