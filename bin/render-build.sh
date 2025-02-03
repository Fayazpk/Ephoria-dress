#!/usr/bin/env bash

set -o errexit

# Install dependencies
npm install -g webpack webpack-cli
bundle install --without development test

# Fix permissions
chmod +x ./bin/rails

# Precompile assets
NODE_OPTIONS=--openssl-legacy-provider webpack --config ./config/webpack/production.js
bundle exec rake assets:precompile

# Migrate the database
bundle exec rake db:migrate
