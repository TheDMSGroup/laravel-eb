# laravel-eb

An example of a minimal Laravel application for automatic scaling in Elastic Beanstalk. Supports automated deployments via BitBucket Pipelines. Uses OctoberCMS as a base.

### Elastic Beanstalk Environment Variables

The following variables need to be set in the Elastic Beanstalk Environment Configuration:

    NR_INSTALL_KEY        - The newrelic installation key.
    APP_URL               - The default url for the environment. This is additionally used for NR notifications and should match what is in bitbucket-pipelines.yml
    AWS_ACCESS_KEY_ID     - The raw AWS key ID (for the laravel cron manager).
    AWS_SECRET_ACCESS_KEY - The raw AWS Secret Access Key (for the laravel cron manager).
    AWS_REGION            - The region within AWS (for the laravel cron manager).
    WORKER_COUNT          - The number of worker processes to be ran at a time on the server.
    WORKER_DELAY          - Delay in seconds between worker job runs.
    USE_CRON              - Must be set to true for the laravel cron manager to run.

### Pipelines Environment Variables

The following variables need to be set in BitBucket Pipelines (if using the service) for automated deployments.

    AWS_ACCESS_KEY_ID     - The raw AWS key ID.
    AWS_SECRET_ACCESS_KEY - The raw AWS Secret Access Key.
    AWS_EB_KEY            - The aws-eb.pem private key, base64 encoded by ```base64 ~./ssh/aws-eb.pem | pbcopy```.
    BB_KEY                - The team Bitbucket private key, base64 encoded by ```base64 ~./ssh/bitbucket.pem | pbcopy```.
    NR_API_KEY_STAGE      - The NewRelic API key for staging/development.
    NR_API_KEY_PROD       - The NewRelic API key for production.
    SLACK_WEBHOOK_URL     - The URL to use for sending a slack deployment notification.

### Begin Development

Run ```composer install``` to build the codebase locally for development and testing. 

### Automated Deployments

#### Staging / Development

This repo will automatically deploy all merges/commits to the "dev" branch to the Development environment, and the "stage" branch to the Staging environment using Bitbucket Pipelines (which must be enabled on the repo). This assumes your environments and branches are named as they are in bitbucket-pipelines.yml and in the .elasticbeanstalk/config.yml file.

#### Production

To deploy to production, find the commit in BitBucket which you wish to deploy and click "Pipelines". Select the pipeline "deploy-to-production" and watch it work.

### Manual Deployments

We can still deploy manually if needed. This requires you to have already setup the awsebcli and have the keys and credentials necessary to perform an Elastic Beanstalk deployment.

 - Build & Update Dependencies:
    - Fresh clone, to ensure you have no local dev files.
    - Run ```rm -rf vendor ; rm -rf modules ; rm -rf composer.lock ; composer install --ansi --no-interaction --no-progress --optimize-autoloader --prefer-dist --no-dev``` to build for production, and update the composer.lock file.
 - Test: 
    - ```git status``` to make sure you have committed your changes (to all repos involved). You may want to commit the updates to the lock file at this time.
    - Test locally, to ensure everything is functioning as expected.
 - Deploy:
    - Run ```bash scripts/deploy.sh <environment>``` or use the ```eb``` CLI application manually.