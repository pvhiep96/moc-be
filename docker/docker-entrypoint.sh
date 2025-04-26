#!/bin/sh

# Exit on fail
set -e

# Function to wait for dependent containers
wait_for_db() {
    # /wait-for-it.sh db:3306
    echo "Waiting for the database to be ready..."
}

# Function to setup the database
setup_database() {
    # Check if the database exists
    if ! bundle exec rails db:version; then
        bundle exec rake db:create
    fi
    bundle exec rake db:migrate
}

# Main execution
main() {
    # Bundle install
    bundle install --jobs=4

    wait_for_db
    setup_database

    # Remove puma pid if existed
    rm -f tmp/pids/server.pid

    # Start services
    bundle exec rails server --port=${APP_PORT:-3000} -b 0.0.0.0

    # Finally call command issued to the docker service
    exec "$@"
}

main "$@"