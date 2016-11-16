local lapis 	 		= require("lapis")
local util  	 		= require("lapis.util")
local validate 		= require("lapis.validate")
local app_helpers = require("lapis.application")

local app = lapis.Application()
app:enable 'etlua'
app.layout = require 'views.layout'

-- ============================================================================
app:get("/", function()
  return "Welcome to Lapis " .. require("lapis.version")
end)

app:get('/form-segment', function()
	return { render = 'form-segment' }
end)

-- ============================================================================
app:post('/segment', app_helpers.capture_errors({ function(self)

  validate.assert_valid(self.params, {
    { "uploaded_file", is_file = true, 'Must provide a file' },
  })






	end, 
	on_error = function(self) 
		return { render = 'form-segment' }
	end
}) )

return app

