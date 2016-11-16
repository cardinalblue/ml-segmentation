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

app:get('/form', function()
	return { render = 'form' }
end)

app:get('/cheerbear', function()
	f = io.open('./DATA/cheerbear.jpg', 'r')
	local data = f:read('*all')
	return data, { content_type = 'image/jpeg', layout = false }
end)

app:post('/convert', function(self)

	-- Requested size
  validate.assert_valid(self.params, {
    { "size", is_integer = true }
  })
	local size = self.params.size
	print('/convert headers=' .. util.to_json(self.req.headers))

	-- Uploaded file
  validate.assert_valid(self.params, {
    { "uploaded_file", is_file = true }
  })
	local file = self.params.uploaded_file
	local tmpname = os.tmpname()
	local tmp = io.open(tmpname, 'w')
	tmp:write(file.content)
	tmp:close()

	os.execute("sips -Z " .. size .. " " .. tmpname)

	local tmp = io.open(tmpname, 'r')
	return tmp:read('*all'), { content_type = 'image/jpeg', layout = false }
end)

return app
