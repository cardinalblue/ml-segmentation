local lapis 	 		= require("lapis")
local util  	 		= require("lapis.util")
local validate 		= require("lapis.validate")
local app_helpers = require("lapis.application")

return function(app)
	
-- ============================================================================
app:get('/form-convert', function()
	return { render = 'form-convert' }
end)

-- ============================================================================
app:post('/convert', app_helpers.capture_errors({ function(self)

  validate.assert_valid(self.params, {
    { "uploaded_file", is_file = true, 'Must provide a file' },
		{ 'size', is_integer = true, 'Must provide a valid size' }
  })
	local size = self.params.size
	local file = self.params.uploaded_file

	-- Uploaded file
	local tmpname = os.tmpname()
	local tmp = io.open(tmpname, 'w')
	tmp:write(file.content)
	tmp:close()

	-- Do conversion
	os.execute("sips -Z " .. size .. " " .. tmpname)

	-- Read and send
	local tmp = io.open(tmpname, 'r')
	return tmp:read('*all'), { content_type = 'image/jpeg', layout = false }
end, 
on_error = function(self) 
	print('errors => ' .. util.to_json(self.errors))
	return { render = 'form-convert' }
end
}) )

-- ============================================================================

end