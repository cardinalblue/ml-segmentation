local lapis 	 		= require("lapis")
local util  	 		= require("lapis.util")
local validate 		= require("lapis.validate")
local app_helpers = require("lapis.application")

local app = lapis.Application()
app:enable 'etlua'
app.layout = require 'views.layout'

app:get("/", function()
  return "Welcome to Lapis " .. require("lapis.version")
end)

app:get('/cheerbear', function()
	f = io.open('./DATA/cheerbear.jpg', 'r')
	local data = f:read('*all')
	return data, { content_type = 'image/jpeg', layout = false }
end)

require('app-convert')(app)
require('app-segment')(app)

return app