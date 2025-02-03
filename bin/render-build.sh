#!/usr/bin/env bash

set -o errexit

# Verify Ruby installation
if ! which ruby; then
  echo "Ruby is not installed. Please install Ruby."
  exit 1
fi

# Ensure correct Ruby path
export PATH="/opt/render/project/rubies/ruby-3.3.5/bin:$PATH"

# Install dependencies using yarn
yarn install --non-interactive || { echo "Yarn install failed. Exiting."; exit 1; }

# Check if webpack and webpack-cli are installed
if ! command -v webpack; then
  echo "webpack-cli is not installed. Exiting."
  exit 1
fi

# Fix permissions
chmod +x ./bin/rails

# Precompile assets
NODE_OPTIONS=--openssl-legacy-provider webpack --config ./config/webpack/production.js
bundle install --without development test
bundle exec rake assets:precompile

# Migrate the database
bundle exec rake db:migrate
