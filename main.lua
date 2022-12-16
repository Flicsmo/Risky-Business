

love.window.setTitle("Risky Business")

baton = require 'baton'
anim8 = require 'anim8'
push = require 'push'

p1 = {}
p2 = {}

assets = {}
assets.bg = love.graphics.newImage("bg.png")
assets.intro = love.graphics.newImage("intro.png")
assets.help = love.graphics.newImage("help.png")
assets.help2 = love.graphics.newImage("help2.png")
assets.help3 = love.graphics.newImage("help3.png")
assets.treasure = love.graphics.newImage("treasure.png")
assets.explosion = love.graphics.newImage("explosion.png")
assets.p1win = love.graphics.newImage("p1win.png")
assets.p2win = love.graphics.newImage("p2win.png")
assets.continue = love.graphics.newImage("continue.png")
assets.title = love.graphics.newImage("title.png")
assets.countdown = love.graphics.newImage("countdown.png")

assets.music = love.audio.newSource("fishnchips.wav", "stream")
assets.fire = love.audio.newSource("landing.ogg", "static")
assets.explode = love.audio.newSource("explode.ogg", "static")

state = 0

love.graphics.setDefaultFilter("nearest", "nearest", 1)
push:setupScreen(320, 180, 1280, 720, {fullscreen = false, pixelperfect = true})

function startGame()
	state = 3
end

function initAnims()
	p1.anim.img, p2.anim.img = love.graphics.newImage("player1.png"), love.graphics.newImage("player2.png")
	local g1, g2 = anim8.newGrid(48, 48, p1.anim.img:getWidth(), p1.anim.img:getHeight()), anim8.newGrid(48, 48, p2.anim.img:getWidth(), p2.anim.img:getHeight())
	p1.anim.idlel = anim8.newAnimation(g1("1-5", 1), 0.2)
	p1.anim.idler = anim8.newAnimation(g1("1-5", 2), 0.2)
	p1.anim.movel = anim8.newAnimation(g1("1-8", 3), 0.09)
	p1.anim.mover = anim8.newAnimation(g1("1-8", 4), 0.09)
	p1.anim.fire = anim8.newAnimation(g1("1-5", 6), 0.05)
	p1.anim.die = anim8.newAnimation(g1("1-8", 8), 0.1, "pauseAtEnd")

	p2.anim.idlel = anim8.newAnimation(g2("1-5", 1), 0.2)
	p2.anim.idler = anim8.newAnimation(g2("1-5", 2), 0.2)
	p2.anim.movel = anim8.newAnimation(g2("1-8", 3), 0.09)
	p2.anim.mover = anim8.newAnimation(g2("1-8", 4), 0.09)
	p2.anim.fire = anim8.newAnimation(g2("1-5", 5), 0.05)
	p2.anim.die = anim8.newAnimation(g2("1-8", 7), 0.1, "pauseAtEnd")

	local g3 = anim8.newGrid(32, 32, assets.explosion:getWidth(), assets.explosion:getHeight())
	assets.explosionAnim = anim8.newAnimation(g3("1-7", 1), 0.08, "pauseAtEnd")

	local g4 = anim8.newGrid(16, 16, 48, 16)
	assets.countdownAnim = anim8.newAnimation(g4("1-3", 1), 1, startGame)
end

function initControls()
	p1.input = baton.new {controls = {
		left = {"key:a"},
		right = {"key:d"},
		fire = {"key:s"},
		menu = {"key:space"},
		fullscreen = {"key:f"},
		exit = {"key:escape"},
		help = {"key:h"}
	}}

	p2.input = baton.new {controls = {
		left = {"key:left"},
		right = {"key:right"},
		fire = {"key:down"}
	}}
end


function love.load()

	p1 = {anim = {current = nil}, x = 37, dir = 1, isMoving = false, bullets = {}, cooldown = 2, hit = false}
	p2 = {anim = {current = nil}, x = 235, dir = 0, isMoving = false, bullets = {}, cooldown = 2, hit = false}
	state = 0

	assets.fire:setVolume(0.45)
	assets.fire:setPitch(2)
	assets.music:setLooping(true)
	assets.music:play()

	initAnims()

	initControls()

end


function love.update(dt)
	p1.input:update()
	p2.input:update()
	if state == 0 then --main menu
		if p1.input:pressed("menu") then
			state = 8
			p2.anim.current = p2.anim.idlel
			p1.anim.current = p1.anim.idler
		end
		if p1.input:pressed("help") then state = 2 end
	elseif state == 1 then --game
		gameUpdate(dt)
	elseif state == 2 then --help 1
		if p1.input:pressed("help") then state = 4 end
	elseif state == 4 then --help 2
		if p1.input:pressed("help") then state = 0 end
	elseif state == 5 then --player hit
		moveBullets(dt)
		if p1.hit then
			p1.anim.current = p1.anim.die
			p2.anim.current = p2.anim.idlel
			if p2.bullets[1] then
				if p2.bullets[1].x < 15 then
					table.remove(p2.bullets, 1)
					state = 6
					assets.explode:play()
				end
			else
				state = 7
			end
		elseif p2.hit then
			p2.anim.current = p2.anim.die
			p1.anim.current = p1.anim.idler
			if p1.bullets[1] then
				if p1.bullets[1].x > 300 then
					table.remove(p1.bullets, 1)
					state = 7
					assets.explode:play()
				end
			else
				state = 6
			end
		end
		p1.anim.current:update(dt)
		p2.anim.current:update(dt)
		p1.cooldown = p1.cooldown + dt
		p2.cooldown = p2.cooldown + dt
	elseif state == 6 then -- p1 wins
		moveBullets(dt)
		p1.anim.current:update(dt)
		p2.anim.current:update(dt)
		assets.explosionAnim:update(dt)
		if p1.input:released("menu") then love.load() end
	elseif state == 7 then -- p2 wins
		moveBullets(dt)
		p1.anim.current:update(dt)
		p2.anim.current:update(dt)
		assets.explosionAnim:update(dt)
		if p1.input:released("menu") then love.load() end
	elseif state == 8 then
		p1.anim.current = p1.anim.idler
		p1.anim.current:update(dt)
		p2.anim.current:update(dt)
		assets.countdownAnim:update(dt)
	end

	if p1.input:pressed("fullscreen") then push:switchFullscreen(1280, 720) end
	if p1.input:pressed("exit") then love.event.quit() end
end


function love.draw()
	push:start()
	love.graphics.draw(assets.bg)
	if state == 0 then
		love.graphics.draw(assets.title, 0, 0)
		love.graphics.draw(assets.intro, 102, 95)
	elseif state == 1 then
		gameDraw()
	elseif state == 2 then
		love.graphics.draw(assets.help, 0, 0)
	elseif state == 3 then
		state = 1
	elseif state == 4 then
		love.graphics.draw(assets.help2, 0, 0)
	elseif state == 5 then
		gameDraw()
	elseif state == 6 then
		gameDraw()
		love.graphics.draw(assets.p1win, 110, 30)
		love.graphics.draw(assets.continue, 98, 90)
	elseif state == 7 then
		gameDraw()
		love.graphics.draw(assets.p2win, 110, 30)
		love.graphics.draw(assets.continue, 98, 120)
	elseif state == 8 then
		gameDraw()
		assets.countdownAnim:draw(assets.countdown, 150, 100)
	end
	push:finish()
end

function gameUpdate(dt)
	--p1 set state
	if p1.input:pressed("fire") then
		fire(1)
		p1.cooldown = 0
		p1.anim.fire:gotoFrame(1)
		local temp = assets.fire:clone()
		temp:play()
	end
	if p1.input:down("left") and p1.x >= 4 and p1.cooldown > 0.18 then
		p1.isMoving = true
		p1.dir = 0
	elseif p1.input:down("right") and p1.x <= 106 and p1.cooldown > 0.18 then
		p1.isMoving = true
		p1.dir = 1
	else
		p1.isMoving = false
	end

	--p1 move and set animation
	if p1.isMoving then
		if p1.dir == 1 then
			p1.anim.current = p1.anim.mover
			p1.x = p1.x + 60 * dt
		else
			p1.anim.current = p1.anim.movel
			p1.x = p1.x - 60 * dt
		end
	else
		if p1.cooldown < 0.25 then
			p1.anim.current = p1.anim.fire
		elseif p1.dir == 1 then
			p1.anim.current = p1.anim.idler
		else
			p1.anim.current = p1.anim.idlel
		end
	end

	--p2 set state
	if p2.input:pressed("fire") then
		fire(2)
		p2.cooldown = 0
		p2.anim.fire:gotoFrame(1)
		local temp2 = assets.fire:clone()
		temp2:play()
	end
	if p2.input:down("left") and p2.x >= 165 and p2.cooldown > 0.18 then
		p2.isMoving = true
		p2.dir = 0
	elseif p2.input:down("right") and p2.x <= 270 and p2.cooldown > 0.18 then
		p2.isMoving = true
		p2.dir = 1
	else
		p2.isMoving = false
	end

	--p2 move and set animation
	if p2.isMoving then
		if p2.dir == 1 then
			p2.anim.current = p2.anim.mover
			p2.x = p2.x + 60 * dt
		else
			p2.anim.current = p2.anim.movel
			p2.x = p2.x - 60 * dt
		end
	else
		if p2.cooldown < 0.25 then
			p2.anim.current = p2.anim.fire
		elseif p2.dir == 1 then
			p2.anim.current = p2.anim.idler
		else
			p2.anim.current = p2.anim.idlel
		end
	end

	p1.cooldown = p1.cooldown + dt
	p2.cooldown = p2.cooldown + dt
	p1.anim.current:update(dt)
	p2.anim.current:update(dt)

	for i,bullet in ipairs(p1.bullets) do
		bullet.x = bullet.x + 90 * dt
		if bullet.x > 340 then
			table.remove(p1.bullets, 1)
		end
		for i,bulletp2 in ipairs(p2.bullets) do
			if bullet.x > bulletp2.x then
				table.remove(p1.bullets, 1)
				table.remove(p2.bullets, 1)
			end
		end
		if bullet.x > p2.x + 12 then
			state = 5
			p2.hit = true
			p2.cooldown = 0
			table.remove(p1.bullets, 1)
		end
	end
	for i,bulletp2 in ipairs(p2.bullets) do
		if bulletp2.x < -10 then
			table.remove(p2.bullets, 1)
		end
		bulletp2.x = bulletp2.x - 90 * dt
		if bulletp2.x < p1.x + 34 then
			state = 5
			p1.hit = true
			p1.cooldown = 0
			table.remove(p2.bullets, 1)
		end
	end
end

function gameDraw()
	if state < 6 then
		love.graphics.draw(assets.treasure, -10, 124)
		love.graphics.draw(assets.treasure, 330, 124, 0, -1, 1)
	else
		if state == 6 then --p1 wins
			if p2.hit then --p2 hit, no extra bullets
				love.graphics.draw(assets.treasure, -10, 124)
				love.graphics.draw(assets.treasure, 330, 124, 0, -1, 1)
			else --left chest exploded
				assets.explosionAnim:draw(assets.explosion, 0, 120)
				love.graphics.draw(assets.treasure, 330, 124, 0, -1, 1)
			end
		end
		if state == 7 then --p2 wins
			if p1.hit then --p1 hit, no extra bullets
				love.graphics.draw(assets.treasure, -10, 124)
				love.graphics.draw(assets.treasure, 330, 124, 0, -1, 1)
			else --right chest exploded
				assets.explosionAnim:draw(assets.explosion, 290, 120)
				love.graphics.draw(assets.treasure, -10, 124)
			end
		end
		if state == 8 then
			love.graphics.draw(assets.treasure, -10, 124)
			love.graphics.draw(assets.treasure, 330, 124, 0, -1, 1)
			love.graphics.draw(assets.help3, 0, 0)
		end
	end


	p1.anim.current:draw(p1.anim.img, p1.x, 109)
	p2.anim.current:draw(p2.anim.img, p2.x, 109)

	for i,bullet in ipairs(p1.bullets) do
		love.graphics.rectangle("fill", bullet.x, 127, 4, 2)
	end
	for i,bullet in ipairs(p2.bullets) do
		love.graphics.rectangle("fill", bullet.x, 127, 4, 2)
	end


end

function fire(p)
	if p == 1 then
		local bullet = {x = p1.x + 42}
		table.insert(p1.bullets, bullet)
	else
		local bullet = {x = p2.x + 2}
		table.insert(p2.bullets, bullet)
	end
end

function moveBullets(dt)
	for i,bullet in ipairs(p1.bullets) do
		bullet.x = bullet.x + 90 * dt
	end
	for i,bullet in ipairs(p2.bullets) do
		bullet.x = bullet.x - 90 * dt
	end
end