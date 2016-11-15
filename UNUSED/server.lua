local pegasus = require 'pegasus' 
local socket = require 'socket'

local server = pegasus:new() 

function sleep(sec)
  socket.select(nil, nil, sec)
end

server:start(function(request, response) 
  print("Path:.." .. request:path())
	local f = io.open('cheerbear.jpg', 'r')
	response:writeFile(f, 'image/jpeg')
	response:close()
end)