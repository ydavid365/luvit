require('helper')
local spawn = require('childprocess').spawn
local os = require('os')

local environmentTestResult = false

function test_process_env()
  local options = {
    env = { TEST1 = 1 }
  }
  local child
  if os.type() == 'win32' then
    child = spawn('cmd.exe', {'/C', 'set'}, options)
  else
    child = spawn('bash', {'-c', 'set'}, options)
  end
  child.stdout:on('data', function(chunk)
    print(chunk)
    if chunk:find('TEST1=1') then
      environmentTestResult = true
    end
  end)
end

function test_process_fail()
  child = spawn('this_executable_will_never_exist_i_hope', {})
  p(child)
  child:on("exit", function(stuff)
    p(stuff)
  end)
end

test_process_env()
test_process_fail()

assert(process.pid ~= nil)

process:on('exit', function()
  assert(environmentTestResult == true)
end)
