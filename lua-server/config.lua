local config = require("lapis.config")

config("development", {
  port = 8080,
})
config("aws-development", {
  port = 8080,
  user = 'root',
  deepmask = '/root/deepmask'
})