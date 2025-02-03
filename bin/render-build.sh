#!/usr/bin/env bash

set -o errexit

# Verify Ruby installation
if ! which ruby; then
  echo "Ruby is not installed. Please install Ruby."
  exit 1
fi

# Install dependencies with npm or yarn as fallback
if ! npm install -g webpack webpack-cli; then
  echo "npm installation failed, trying yarn..."
  yarn add -D webpack webpack-cli || { echo "Failed to install webpack and webpack-cli"; exit 1; }
fi

# Ensure correct Ruby path
export PATH="/opt/render/project/rubies/ruby-3.3.5/bin:$PATH"

# Fix permissions
chmod +x ./bin/rails

# Precompile assets
NODE_OPTIONS=--openssl-legacy-provider webpack --config ./config/webpack/production.js
bundle install --without development test
bundle exec rake assets:precompile

# Migrate the database
bundle exec rake db:migrate
