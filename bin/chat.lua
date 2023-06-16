-- P2P chat system
component = require("component")
event = require("event")
thread = require("thread")
modem = component.modem

modem.open(99)
io.write("Enter your name: ")
name = io.read()

function sendMsg()
  busy = true
  io.write("Enter message (type 'exit' to exit): ")
  msg = io.read()
  busy = false
  if msg == "exit" then
    os.exit()
  end
  modem.broadcast(99, name..": "..msg)
end

busy = false -- If we are typing a message

function receiveMsg()
  if busy then os.sleep(0.05) return  end
  local _, me, from, port, _, message = event.pull("modem_message")
  --if me == from then return end
  io.write(message.."\n")
end

thread.create(function()
  while true do
    receiveMsg()
  end
end)

while true do
    sendMsg()
    os.sleep(0.2)
end
