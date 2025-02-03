const { environment } = require('@rails/webpacker')

// Set the node configuration to false
environment.config.set('node', false)

module.exports = environment.toWebpackConfig()
