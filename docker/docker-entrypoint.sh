#!/bin/sh

# Exit on fail
set -e

# Function to wait for dependent containers
wait_for_db() {
    echo "Waiting for PostgreSQL to be ready..."
    # Wait for PostgreSQL to be ready
    while ! nc -z db 5432; do
      sleep 1
    done
    echo "PostgreSQL is ready!"
}

# Function to setup the database
setup_database() {
    echo "Setting up database..."
    # Create database if it doesn't exist
    bundle exec rails db:create || true
    # Run migrations
    bundle exec rails db:migrate
    # Run seeds if in development
    if [ "$RAILS_ENV" = "development" ]; then
        bundle exec rails db:seed
    fi
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
