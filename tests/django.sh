#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/common.sh


SRV_PID=$(ps -elf | grep ':37569' | grep -v grep | awk '{print $4}')
if [ "$SRV_PID" != "" ]; then
	printf "Killing old django PID: $SRV_PID ... "
	kill -9 $PUMA_PID
	success 'done'
fi
copy_deployment_files 'python' $SCRIPT_PATH/resources/django_project

title 'TEST - editing configs'
cd $COPY_PROJECT_DIR/python-project
PROJECT_DEPLOY_DIR="$COPY_PROJECT_DIR/python-project/deploy"
echo "\nDEPLOYMENT_DIR=$TEST_WORKING_DIR\nDEPLOYMENT_SERVER=localhost\nDEPLOYMENT_SERVER_USER=$USER\nREPO=file://$COPY_PROJECT_DIR/python-project\nSERVICE_NAME=python-deploy-test\nLINKED_FILES=\nLINKED_DIRS=\"venv uploads logs tmp/sockets tmp/pids\"" >> deploy/app-config.sh
echo "PROJECT_ENVIRONMENT=default\nGIT_BRANCH=master\nSERVICE_PORT=37569" >> deploy/environments/default/config.sh
cat deploy/app-config.sh
cat deploy/environments/default/config.sh
title 'TEST - deploying default environment'
rm -rf $TEST_WORKING_DIR
PROJECT_DEPLOY_DIR=$PROJECT_DEPLOY_DIR sh $SCRIPT_PATH/../scripts/deploy.sh default
cd $TEST_WORKING_DIR/python-deploy-test/default/current
title 'TEST - check web application'
wget localhost:37569
printf 'Checking index page contents ... '
if [ $(grep -c 'The install worked successfully! Congratulations!' index.html) -eq 1 ]; then
	success 'success!'
else
	error 'fail! :('
fi
sh deploy/run.sh stop
cd $SCRIPT_PATH/../
rm -rf /tmp/deploy-scripts