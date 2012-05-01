require('helper')
local fixture = require('./fixture-tls')
local net = require('net')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.certKey,
}

local server = tls.createServer(options, function(socket)
  print('hi')
  serverConnected = true
  socket:write('Hello')
  socket:destroy()
end)

server:listen(fixture.commonPort, function()
  local socket
  print('listening')
  socket = net.createConnection(fixture.commonPort, '127.0.0.1', function(err)
    if err then
      assert(err)
    end
    print('connected')
    local client
    client = tls.connect({socket = socket, host = '127.0.0.1', port = fixture.commonPort}, function()
      print('tls connected')
      clientConnected = true
      local data = ''
      client:on('data', function(chunk)
        data = data + chunk
      end)
      client:on('end', function()
        assert.equal(data, 'Hello')
        server:close()
      end)
    end)
  end)
end)

process:on('exit', function()
  assert(serverConnected)
  assert(clientConnected)
end)
