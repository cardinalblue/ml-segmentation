local config = require("lapis.config")

config("development", {
  port = 9090,
})
config("aws-development", {
  port = 9090,
  user = 'root',
  deepmask = '/root/deepmask'
})