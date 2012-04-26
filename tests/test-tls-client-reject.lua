require('helper')
local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  key = fixture.loadPEM('agent2-key'),
  cert = fixture.loadPEM('agent2-cert'),
}

local client_options = {
  port = fixture.commonPort,
  host = '127.0.0.1',
}

local connectCount = 0

local server
server = tls.createServer(options, function(socket)
  connectCount = connectCount + 1
  socket:on('data', function(chunk)
    print('chunk: ' .. chunk)
    assert(chunk == 'ok')
  end)
end)

server:on('clientError', function(err)
  -- clientError shouldn't ever happen
  p(err)
  assert(false)
end)

local authorized = function()
  local options = client_options
  options.rejectUnauthorized = true
  options.ca = fixture.caPem

  local socket
  socket = tls.connect(options, function()
    assert(socket.authorized)
    socket:write('ok')
    socket:destroy()
    server:close()
  end)
  socket:on('error', function(err)
    print("authorized error")
    print(err)
    --assert(false)
  end)
end

local rejectUnauthorized = function()
  local options = client_options
  options.rejectUnauthorized = true

  local socket2
  socket2 = tls.connect(options, function()
    socket:write('ng')
    assert(false)
  end)

  socket2:on('error', function(err)
    p(err)
    p("got error")
    authorized()
  end)
end

local unauthorized = function()
  local socket
  socket = tls.connect(client_options, function()
    assert(socket.authorized == false)
    socket:write('ok')
    socket:finish()
    rejectUnauthorized()
  end)
  socket:on('error', function(err)
    print("unauthorized error")
    print(err)
    --assert(false)
  end)
end

server:listen(fixture.commonPort, function()
  unauthorized()
end)

process:on('exit', function()
  assert(connectCount == 3)
end)
