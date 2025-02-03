const { environment } = require('@rails/webpacker')

// Ensure the node configuration is correct
environment.config.set('node', {
  __dirname: true,
  __filename: true,
  global: true
})

module.exports = environment.toWebpackConfig()
