ds_push() {
	if [ "$1" = "" ] || [ "$2" = "" ]; then
		error "push: git-bare: Too few arguments given to ds_push"
	fi

	cd "$1"
	TIMESTAMP=$(date +%s)
	BARE_REPO_SCRIPT_DIR=/tmp/deployer-$TIMESTAMP

	mkdir -p $BARE_REPO_SCRIPT_DIR
	cp "$1/$DS_DIR/config.sh" $BARE_REPO_SCRIPT_DIR/config.sh
	cp $SCRIPT_PATH/../steps/push/lib/post-deploy/post-deploy-utils.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/../steps/push/lib/git-bare-resources/post-receive-utils.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/util.sh $BARE_REPO_SCRIPT_DIR/
	cp $SCRIPT_PATH/../steps/push/lib/git-bare-resources/bare-repo.sh $BARE_REPO_SCRIPT_DIR/
	POST_RECEIVE_HOOK="$2/push/git-bare/post-receive-hook"
	ENV_POST_RECEIVE_HOOK="$PROJECT_DEPLOY_DIR/environments/$PROJECT_ENVIRONMENT/post-receive"
	PROJECT_POST_RECEIVE_HOOK="$PROJECT_DEPLOY_DIR/post-receive"
	if [ -f "$ENV_POST_RECEIVE_HOOK" ]; then
		POST_RECEIVE_HOOK="$ENV_POST_RECEIVE_HOOK"
	elif [ -f "$PROJECT_POST_RECEIVE_HOOK" ]; then
		POST_RECEIVE_HOOK="$PROJECT_POST_RECEIVE_HOOK"
	fi

	info "Copying generic post-receive hook $POST_RECEIVE_HOOK"
	cp $POST_RECEIVE_HOOK $BARE_REPO_SCRIPT_DIR/

	info "Copying scripts to create bare git repo"
	scp -o StrictHostKeyChecking=no -P$DEPLOYMENT_SERVER_PORT -r $BARE_REPO_SCRIPT_DIR $DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:/tmp/ 2>&1 | indent
ssh -o "StrictHostKeyChecking no" -p $DEPLOYMENT_SERVER_PORT -t $DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER << EOSSH
cd $BARE_REPO_SCRIPT_DIR && sh ./bare-repo.sh
EOSSH
	REMOTE_GIT_BARE_REPO=ssh://$DEPLOYMENT_SERVER_USER@$DEPLOYMENT_SERVER:$DEPLOYMENT_SERVER_PORT/~/.repos/$SERVICE_NAME/$PROJECT_ENVIRONMENT.git

	info "Deploying $PROJECT_ENVIRONMENT to $REMOTE_GIT_BARE_REPO"

	cd "$1"
	git remote add deploy $REMOTE_GIT_BARE_REPO 2>&1 | indent
	GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -u deploy $DEPLOY_BRANCH -f
}