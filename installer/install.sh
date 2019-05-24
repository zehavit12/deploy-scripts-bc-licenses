#!/bin/sh

set -e

SCRIPT_PATH=$(dirname $(readlink -f $0))
. $SCRIPT_PATH/../scripts/util.sh

if [ ! -d "$2" ]; then
	error "No such directory: $2"
fi

DEPLOY_DIR=""
RELATIVE_DEPLOY=""
if [ "$1" = "java" ]; then
	RELATIVE_DEPLOY="deploy"
elif [ "$1" = "rails" ]; then
	RELATIVE_DEPLOY="config/deploy"
else
	error "Project type $1 currently unsupported"
fi

DEPLOY_DIR="$2/$RELATIVE_DEPLOY"
printf "\nCopying deployment files to $DEPLOY_DIR ... "
mkdir -p $DEPLOY_DIR
if [ ! -f "$DEPLOY_DIR/deploy.sh" ]; then
	cp $SCRIPT_PATH/../deploy.sh $DEPLOY_DIR
fi
if [ ! -f "$DEPLOY_DIR/app-config.sh" ]; then
	cp "$SCRIPT_PATH/../default-$1/app-config.sh" $DEPLOY_DIR
fi
if [ ! -d "$DEPLOY_DIR/default" ]; then
	cp -r "$SCRIPT_PATH/../default-$1" $DEPLOY_DIR/default
	rm $DEPLOY_DIR/default/app-config.sh
fi
success "done"

line
info "Please edit the variables in app-config.sh to suit your deployment\n"
info "A sample environment named 'default' has been copied to $DEPLOY_DIR"
info "Please rename it to your desired environment (eg. staging) name and edit the config.sh"
info "within the folder according to your deployment settings\n"
info "Once you have made the edits, you can deploy by executing the 'deploy.sh' script"
info "from your project directory. For example:\n"
info "\tsh $RELATIVE_DEPLOY/deploy.sh staging"
line