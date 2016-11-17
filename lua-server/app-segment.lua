local lapis 	 		= require("lapis")
local util  	 		= require("lapis.util")
local validate 		= require("lapis.validate")
local app_helpers = require("lapis.application")

-- ============================================================================

require 'image'
local coco  = require 'coco'

local config = {
	model		= 
	gpu  		= 1,
	np			= 5,				-- Number of proposals
	si			= -2.5,			-- Initial scale
	sf   		= .5,				-- Final scale
	ss			= .5,				-- Scale step
	dm			= false,		-- Use DeepMask or SharpMask	
}

-- ============================================================================

function get_model_path()
	local deepmask_path = os.gentenv('DEEPMASK')
	if (config.dm) then
		return deepmask_path .. '/pretrained/deepmask'
	else
		return deepmask_path .. '/pretrained/sharpmask'
	end
end


function get_infer()

	if !os.gentenv('DEEPMASK') then
		
		-- Mock for testing of the infer object
		return {
			forward = function(self, img)
				-- Do nothing
			end,
			getTopProps = function(self, thr, h, w)
				-- For now return a blank one
				local topMasks = torch.ByteTensor()
				topMasks:resize(config.np, h, w):zero()
				return topMasks
			end			
		}

	else

		require 'torch'
		require 'cutorch'

		print('>>>> Configuring Torch')
		torch.setdefaulttensortype('torch.FloatTensor')
		cutorch.setDevice(config.gpu)
		local meanstd = {
			mean = { 0.485, 0.456, 0.406 }, 
			std = { 0.229, 0.224, 0.225 }
		}

		-- Load model
		print('>>>> Loading models...')
		paths.dofile('DeepMask.lua')
		paths.dofile('SharpMask.lua')

		print('>>>> Loading model file... ' .. get_model_path())
		local m = torch.load(get_model_path() .. '/model.t7')
		local model = m.model
		model:inference(config.np)
		model:cuda()

		-- create inference module
		local scales = {}
		for i = config.si, config.sf, config.ss do 
			table.insert(scales, 2^i) 
		end

		if torch.type(model)=='nn.DeepMask' then
		  paths.dofile('InferDeepMask.lua')
		elseif torch.type(model)=='nn.SharpMask' then
		  paths.dofile('InferSharpMask.lua')
		end

		return Infer{
		  np 			= config.np,
		  scales 	= scales,
		  meanstd = meanstd,
		  model 	= model,
		  dm 			= config.dm,
		}

	end

end

-- Note: returns the tmp file's NAME
function tmp_with_content(content)
	local filename = os.tmpfile()
	local f = io.open(filename, 'wb')
	f:write(content)
	f:close()
	return filename
end

	
-- ============================================================================
-- ============================================================================
-- ============================================================================

return function(app)	-- Module returns a function to be called with `app`

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

	local tmp = tmp_with_content(self.params.uploaded_file.content)

	local img = image.load(tmp)
	local h,w = img:size(2), img:size(3)
	print('>>>> Received image sized ' .. w .. ', ' .. h)

	-- Do segmentation
	local infer = get_infer()
	infer:forward(img)													-- Forward all scales
	local masks, _ = infer:getTopProps(.2, h, w)	-- Get top propsals

	-- Draw out the masks
	local outimg = img:clone()
	coco.maskApi.drawMasks(outimg, masks, 10)
	local outtmp = os.tmpfile()
	image.saveJPG(outtmp, outimg)
	local outdata = io.open(outtmp, 'rb'):read('*all')

	-- Maintenance
	collectgarbage()

	-- Return 
	return outdata, { content_type = 'image/jpeg', layout = false }
end, 
	on_error = function(self) 
		return { render = 'form-segment' }
	end
}) )

return app
end
