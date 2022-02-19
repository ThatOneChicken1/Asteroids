require "simple-slider"

-- initializing menu
local game_state = 'menu'
local menus = { 'Play', 'Settings', 'Quit' }
local selected_menu_item = 1
local window_width
local window_height
local font_height

-- menu functions
local draw_menu
local menu_keypressed
local draw_settings
local settings_keypressed
local draw_game
local game_keypressed

function love.load()
  pauseCounter = 0
  turnSpeed = 10
  levelSpeedInit = 1
  levelSpeedIncrement = 0

  levelSpeed = levelSpeedInit

  -- get the width and height of the game window in order to center menu items
  window_width, window_height = love.graphics.getDimensions()

  -- use a big font for the menu
  local font = love.graphics.setNewFont(30)

  -- get the height of the font to help calculate vertical positions of menu items
  font_height = font:getHeight()

  highscore = 0
  roundedhighscore = 0
  -- create a new slider
  turnSpeedSlider = newSlider(400, 500, 300, 10, 1, 10, function (t) turnSpeed = t end)

  -- create another new slider
  volumeSlider = newSlider(400, 300, 300, 1, 0, 1, function (v) Theme:setVolume(v) end)
  -- create another 'nother new Slider
  levelIncrementSlider = newSlider(400, 100, 300, 0, 0, 10, function (l) levelSpeedIncrement = l/10 end)

  source = love.audio.newSource("resources/asteroid_explosion_c.mp3", "stream")
  Theme = love.audio.newSource("resources/War_Theme.mp3", "stream")
  winSound = love.audio.newSource("resources/win.wav", "stream")
  loseSound = love.audio.newSource("resources/lose.wav", "stream")
  -- Theme = love.audio.newSource("resources/turn_to_the_sun.ogg", "stream")
  -- Theme = love.audio.sewSource("resources/a_new_beginning.ogg", "stream")
  Theme:setLooping(true)
  Theme:play()
  arenaWidth = 800
  arenaHeight = 600
  bulletTimerLimit = 0.5
  bulletRadius = 3
  shipRadius = 10
  tinyRadius = 3
  shipCircleDistance = 15
  earth_image = love.graphics.newImage("resources/earth.png")
  ship_image = love.graphics.newImage("resources/spaceshippy.png")
  shipEngine_image = love.graphics.newImage("resources/spaceshippy_fire.png")
  shipOffset = 12
  asteroid_image = love.graphics.newImage("resources/asteroid.png")
  asteroidImageSize = 160

  asteroidStages = {
    {
      speed = 120,
      radius = 15,
      scale = 0.15,

    },
    {
      speed = 70,
      radius = 30,
      scale = 0.3,
    },
    {
      speed = 50,
      radius = 50,
      scale = 0.5,
    }
  }

  Score = 0
  roundedScore = 0
  reset()

end
-- love.load

function you_lost()
  --Score = 0
  levelSpeed = levelSpeedInit
  loseSound:play()
  game_state = 'pause'
  pauseCounter = 0
end

function level_up()
  winSound:play()
  levelSpeed = levelSpeed + levelSpeedIncrement
end

function reset()
  --Score = 0
  shipX = arenaWidth / 2
  shipY = arenaHeight / 2
  shipAngle = 0
  shipSpeedX = 0
  shipSpeedY = 0


  bullets = {}


  bulletTimer = bulletTimerLimit
  --planetHealth = 4

  asteroids = {
    {
      x = 300,
      y = 100,
    },
    {
      x = arenaWidth - 100,
      y = 100,
    },
    {
      x = arenaWidth / 2,
      y = arenaHeight - 100,
    },
  }


  -- choose directions for asteroids
  for asteroidIndex, asteroid in ipairs(asteroids) do
    asteroid.angle = love.math.random() * (2 * math.pi)
    asteroid.stage = #asteroidStages
  end
  -- for asteroidIndex
end

function love.update(dt)

  volumeSlider:update()
  turnSpeedSlider:update()
  levelIncrementSlider:update()
  --turnSpeed = 10
  ThemeVolumeRaw = Theme:getVolume() * 100
  ThemeVolume = math.floor (ThemeVolumeRaw) / 10

  turnSpeed = math.floor (turnSpeed)
  levelSpeedIncrement = math.floor(levelSpeedIncrement*10)/10

  if game_state == 'game' then

    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
      shipAngle = shipAngle + turnSpeed * dt
    end

    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
      shipAngle = shipAngle - turnSpeed * dt
    end

    shipAngle = shipAngle % (2 * math.pi)

    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
      local shipAccel = 250
      shipSpeedX = shipSpeedX + math.cos(shipAngle) * shipAccel * dt
      shipSpeedY = shipSpeedY + math.sin(shipAngle) * shipAccel * dt
    end

    local function areCirclesIntersecting(aX, aY, aRadius, bX, bY, bRadius)
      return (aX - bX)^2 + (aY - bY)^2 <= (aRadius + bRadius)^2
    end

    for bulletIndex = #bullets, 1, -1 do
      local bullet = bullets[bulletIndex]

      bullet.timeLeft = bullet.timeLeft - dt

      if bullet.timeLeft <= 0 then
        table.remove(bullets, bulletIndex)
      else

        local bulletSpeed = 500
        bullet.x = (bullet.x + math.cos(bullet.angle) * bulletSpeed * dt)
        % arenaWidth
        bullet.y = (bullet.y + math.sin(bullet.angle) * bulletSpeed * dt)
        % arenaHeight
      end

      for asteroidIndex = #asteroids, 1, -1 do
        local asteroid = asteroids[asteroidIndex]

        if areCirclesIntersecting(
          bullet.x, bullet.y, bulletRadius,
          asteroid.x, asteroid.y,
          asteroidStages[asteroid.stage].radius
        ) then
          love.audio.play( source )
          table.remove(bullets, bulletIndex)
          Score = Score + levelSpeed
	  roundedScore = math.floor(Score)
          if Score > highscore then
            highscore = Score
	    roundedhighscore = roundedScore
          end


          if asteroid.stage > 1 then
            local angle1 = love.math.random() * (2 * math.pi)
            local angle2 = (angle1 - math.pi) % (2 * math.pi)

            table.insert(asteroids, {
              x = asteroid.x,
              y = asteroid.y,
              angle = angle1,
              stage = asteroid.stage - 1,
            })
            table.insert(asteroids, {
              x = asteroid.x,
              y = asteroid.y,
              angle = angle2,
              stage = asteroid.stage - 1,
            })
          end

          table.remove(asteroids, asteroidIndex)
          break
        end
      end
    -- for asteroidIndex
  end
  -- for bulletIndex

  -- Earth gravity
  local disttoEarth = ((shipX+250)^2 + (shipY+250)^2)^0.5
  local gravAccel = 5/disttoEarth
  shipSpeedX = shipSpeedX - gravAccel * (shipX + 250) * dt
  shipSpeedY = shipSpeedY - gravAccel * (shipY + 250) * dt

  shipX = (shipX + shipSpeedX * dt) % arenaWidth
  shipY = (shipY + shipSpeedY * dt) % arenaHeight

  -- create bullets if key down
  bulletTimer = bulletTimer + dt
  if love.keyboard.isDown('space') then
    if bulletTimer >= bulletTimerLimit then
      bulletTimer = 0

      table.insert(bullets, {
        x = shipX + math.cos(shipAngle) * shipRadius,
        y = shipY + math.sin(shipAngle) * shipRadius,
        angle = shipAngle,
        timeLeft = 4,
      })
    end
  end

  -- move the asteroids
  for asteroidIndex, asteroid in ipairs(asteroids) do
    asteroid.x = (asteroid.x + math.cos(asteroid.angle)
      * asteroidStages[asteroid.stage].speed * levelSpeed * dt) % arenaWidth
    asteroid.y = (asteroid.y + math.sin(asteroid.angle)
      * asteroidStages[asteroid.stage].speed * levelSpeed * dt) % arenaHeight

    -- collision test

    if areCirclesIntersecting(
    shipX, shipY, shipRadius,
    asteroid.x, asteroid.y, asteroidStages[asteroid.stage].radius
  ) then
    you_lost()
    reset()
    break
  end
end

-- test if ship collided with Earth
if areCirclesIntersecting(
shipX, shipY, shipRadius,
-250, -250, 500
) then
  you_lost()
  reset()
end

-- RESET GAME IF NO ROIDS
if #asteroids == 0 then
  level_up()
  reset()
end


end
-- gamestate == 'game'

if game_state == 'pause' then
  pauseCounter = pauseCounter + dt
  if pauseCounter >= 2 then
     Score = 0
     roundedScore = 0
    game_state = 'game'
  end
end


end
-- love.update

-----------------------------------------------------------------

function love.draw()

  if game_state == 'menu' then
    draw_menu()

  elseif game_state == 'settings' then
    draw_settings()

  elseif game_state == 'game' then
    draw_game()

  elseif game_state == 'pause' then
    draw_game()
  end

  if game_state == 'game' or game_state == 'menu' then
    for asteroidIndex, asteroid in ipairs(asteroids) do
      local asteroidScale = asteroidStages[asteroid.stage].scale
      local asteroidOffset = asteroidImageSize * asteroidScale / 2
      love.graphics.setColor(1,1,1)
      love.graphics.draw(asteroid_image, asteroid.x - asteroidOffset, asteroid.y - asteroidOffset, 0,
      asteroidScale, asteroidScale)
    end

    -- if player is half on edge of screen, draw player half on other side
    for y = -1, 1 do
      for x = -1, 1 do
        love.graphics.origin()
        love.graphics.translate(x * arenaWidth, y * arenaHeight)

        -- draw the bullets
        for bulletIndex, bullet in ipairs(bullets) do
          love.graphics.setColor(255, 165, 0)
          love.graphics.circle('fill', bullet.x, bullet.y, bulletRadius)
        end
        -- for bulletIndex
      end
      -- for x = -1, 1 do
    end
    -- for y = -1, 1 do
  end
  -- for asteroidIndex

  love.graphics.origin()
  -- draw planet Earth image
  love.graphics.setColor(1,1,1)
  love.graphics.draw(earth_image, -300, -300, 0, 1, 1)

end
-- love.draw

function draw_menu()

  local horizontal_center = window_width / 2
  local vertical_center = window_height / 2
  local start_y = vertical_center - (font_height * (#menus / 2))

  -- draw highscore when in menu/escape screen
  love.graphics.print("Highscore: " .. roundedhighscore, 575, 550)

  -- draw game title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Asteroids", 0, 150, window_width, 'center')

  -- draw menu items
  for i = 1, #menus do

    -- currently selected menu item is yellow
    if i == selected_menu_item then
      love.graphics.setColor(1, 1, 0, 1)

      -- other menu items are white
    else
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- draw this menu item centered
    love.graphics.printf(menus[i], 0, start_y + font_height * (i-1), window_width, 'center')

  end
end

function draw_settings()
-- draw theme volume slider text
  love.graphics.printf("Theme Volume Slider", 0, window_height / 2.75 - font_height / 2, window_width, 'center')
  love.graphics.printf("  " .. ThemeVolume, 0, window_height / 2 - font_height / 2, window_width + 400, 'center')
-- draw theme volume slider
  love.graphics.setLineWidth(4)
  volumeSlider:draw()
-- draw sensitivity slider text
  love.graphics.printf("Turn Speed Sensitivity Slider", 0, window_height / 1.5 - font_height / 2, window_width, 'center')
  love.graphics.printf("  " .. turnSpeed, 0, window_height / 1.20 - font_height / 2, window_width + 425, 'center')
-- draw sensitivity slider
  turnSpeedSlider:draw()
-- draw speed increment slider text
  love.graphics.printf("Speed Increment Slider", 0, window_height / 14 - font_height / 2, window_width, 'center')
  love.graphics.printf("  " .. levelSpeedIncrement, 0, window_height / 6 - font_height / 2, window_width + 400, 'center')
-- draw speed increment slider
  levelIncrementSlider:draw()
end

function draw_game()
  -- draw shippy!
  love.graphics.setColor(1,1,1)
  love.graphics.print("Score: " .. roundedScore , 650, 550)
  --love.graphics.print("p: " .. pauseCounter , 650, 550)
  if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
    love.graphics.draw(shipEngine_image, shipX, shipY, shipAngle + math.pi / 2, 1, 1, shipOffset, shipOffset)
  else
    love.graphics.draw(ship_image, shipX, shipY, shipAngle + math.pi / 2, 1, 1, shipOffset, shipOffset)
  end
end

function love.keypressed(key, scan_code, is_repeat)

  if game_state == 'menu' then
    menu_keypressed(key)

  elseif game_state == 'settings' then
    settings_keypressed(key)

  else
    -- game_state == 'game'
    game_keypressed(key)

  end

end
-- buttons for the menu
function menu_keypressed(key)

  -- pressing Esc on the main menu quits the game
  if key == 'escape' then
    love.event.quit()

    -- pressing up selects the previous menu item, wrapping to the bottom if necessary
  elseif key == 'up' then

    selected_menu_item = selected_menu_item - 1

    if selected_menu_item < 1 then
      selected_menu_item = #menus
    end

    -- pressing down selects the next menu item, wrapping to the top if necessary
  elseif key == 'down' then

    selected_menu_item = selected_menu_item + 1

    if selected_menu_item > #menus then
      selected_menu_item = 1
    end

    -- pressing enter changes the game state (or quits the game)
  elseif key == 'return' or key == 'kpenter' then

    if menus[selected_menu_item] == 'Play' then
      game_state = 'game'

    elseif menus[selected_menu_item] == 'Settings' then
      game_state = 'settings'

    elseif menus[selected_menu_item] == 'Quit' then
      love.event.quit()
    end

  end
end

function settings_keypressed(key)

  if key == 'escape' then
    game_state = 'menu'
  end

end

function game_keypressed(key)

  if key == 'escape' then
    game_state = 'menu'
  end

end
