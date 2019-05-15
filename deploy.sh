#!/bin/sh

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/app-config.sh

if [ "$1" = "" ]; then
    echo "No environment set"
    exit
else
    PROJECT_ENVIRONMENT="$1"
    if [ ! -f $SCRIPT_PATH/$PROJECT_ENVIRONMENT/config.sh ]; then
        echo "Please initialize deploy/$PROJECT_ENVIRONMENT/config.sh with vars PROJECT_ENVIRONMENT, SERVICE_NAME and SERVICE_PORT"
        exit
    fi
    . $SCRIPT_PATH/$PROJECT_ENVIRONMENT/config.sh
fi

BARE_REPO_SCRIPT_DIR=/tmp/deployer

mkdir -p $BARE_REPO_SCRIPT_DIR
cat $SCRIPT_PATH/app-config.sh $SCRIPT_PATH/$PROJECT_ENVIRONMENT/config.sh > $BARE_REPO_SCRIPT_DIR/config.sh
cp $SCRIPT_PATH/bare-repo.sh $BARE_REPO_SCRIPT_DIR/
cp $SCRIPT_PATH/$PROJECT_ENVIRONMENT/git-hook-post-receive $BARE_REPO_SCRIPT_DIR/

echo "Copying scripts to create bare git repo"
scp -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER:/tmp/
ssh -t $DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER 'cd /tmp/deployer && sh ./bare-repo.sh'

PROJECT_ENVIRONMENT=$PROJECT_ENVIRONMENT sh $SCRIPT_PATH/$BUILD.sh

REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SSH_USER@$DEPLOYMENT_SERVER/home/$DEPLOYMENT_SSH_USER/repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git
echo "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

if [ ! -d $SCRIPT_PATH/repo ]; then
	echo "No deployment repo created by $BUILD script. exiting"
	exit
fi
cd $SCRIPT_PATH/repo
git remote rm fincon-dev
git remote add fincon-dev $REMOTE_GIT_BARE_REPO
git push fincon-dev master -f
echo "Deleting deployment repo $SCRIPT_PATH/repo"
rm -rf $SCRIPT_PATH/repo
