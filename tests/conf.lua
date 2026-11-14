-- Lets `love tests` run headless: no window, graphics or audio.
function love.conf(t)
  t.window = false
  t.modules.window = false
  t.modules.graphics = false
  t.modules.audio = false
  t.modules.sound = false
  t.modules.joystick = false
end
