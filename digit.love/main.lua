function love.load()
    math.randomseed( os.time() )
	spriteWidth = 40
	spriteHeight = 40
    
    map_w = 10
    map_h = 17
    map_x = 0
    map_y = 80
    map_offset_x = 30
    map_offset_y = 30
    tile_w = 40
    tile_h = 40
    
    tiles = {}
    treasure = {}
    map={}
    
    dig_sound = love.audio.newSource("assets/dig_normal.wav", "static")
    land_sound = love.audio.newSource("assets/plop.wav", "static")
    bump_sound = love.audio.newSource("assets/bump.wav", "static")
    
    -- build out map
    for x=0, map_w do
        map[x] = {}
       for y=0, map_h do
          map[x][y] = 0
       end
    end
    
    -- set up elements
    dig_caves(4)
    bury_ancient_treasure()
    
    mobs = {}
    
    
    
    player_x = 5
    player_y = 0
    player_status = 'fine'
    player_x_display = player_x*spriteWidth
    player_y_display = player_y*spriteHeight+map_y
    
    map[player_x][player_y] = 2
end

function love.draw()
    math.randomseed( os.time() )
    draw_map()
    
    for i=1, #treasure do
        --print(treasure[i].x)
        love.graphics.setColor(214, 219, 46)
        love.graphics.rectangle( 'fill', map_x+(treasure[i].x*tile_w), map_y+(treasure[i].y*tile_h),  tile_w, tile_h)
    end
    
	love.graphics.setColor(255, 255, 255)
    love.graphics.print(player_status, 0, 0)
    love.graphics.rectangle( 'fill', player_x_display, player_y_display, spriteWidth, spriteHeight )
    
    
end

function love.update(dt)
    
    if player_status == "fine" then
        player_x_display = player_x*spriteWidth
        player_y_display = player_y*spriteHeight+map_y
    elseif player_status == "falling" then
       player_y = player_y+1
       
       if map[player_x][player_y+1] == 0 then
          player_status = "fine"
          land_sound:play()
       end
       
       if player_y == map_h then
           player_status = "fine"
           land_sound:play()
       end
    end
    
end

function draw_map()
   for x=0, map_w do
      for y=0, map_h do
        
        if map[x][y] == 0 then
        -- dirt
        love.graphics.setColor(133, 94, 33)
        love.graphics.rectangle( 'fill', map_x+(x*tile_w), map_y+(y*tile_h),  tile_w, tile_h)
        elseif map[x][y] == 1 then
        -- grass
        love.graphics.setColor(67, 158, 36)
        love.graphics.rectangle( 'fill', map_x+(x*tile_w), map_y+(y*tile_h),  tile_w, tile_h)
        elseif map[x][y] == 2 then
        -- dug out
        love.graphics.setColor(64, 40, 3)
        love.graphics.rectangle( 'fill', map_x+(x*tile_w), map_y+(y*tile_h),  tile_w, tile_h)
        end
        
        love.graphics.setColor(255, 255, 255)
        --love.graphics.print(x .. ", " .. y, map_x+(x*tile_w), map_y+(y*tile_h))
      end
   end
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end
   
   if key == "down" then
       
       if player_y + 1 == map_h+1 then
           
       else
          player_collide(player_x, player_y + 1) 
          
       end
       
       if map[player_x][player_y+1] == 2 then
            player_status = "falling"
       end
       
   end
   
   if key == "up" then
       if player_y - 1 < 0 then
       
       elseif map[player_x][player_y - 1] == 2 then
           
       else
           player_collide(player_x, player_y - 1)
       end
       
       if map[player_x][player_y+1] == 2 then
            player_status = "falling"
       end
   end
   
   if key == "left" then
       if player_x - 1 < 0 then
       
       else
           player_collide(player_x - 1, player_y)
       end
       
       if map[player_x][player_y+1] == 2 then
            player_status = "falling"
       end
   end
   
   if key == "right" then
       if player_x + 1 == map_w+1 then
           
       else
           player_collide(player_x + 1, player_y)
       end
       
       if map[player_x][player_y+1] == 2 then
            player_status = "falling"
       end
   end
   
   for i=1, #treasure do
       if treasure[i].x == player_x then
           if treasure[i].y == player_y then
               treasure[i].status = "gotten"
           end
       end
   end
   
end

-- this takes in the SUGGESTED new x,y pos for the player based on the user input
function player_collide(x,y)
    
    move_allowed = false
    
    print(x .. ", " .. y)
    print(map[x][y])
    
    -- if it's dirt
    if map[x][y] == 0 then
        move_allowed = true
        map[x][y] = 2
        -- play the appropriate sound
        dig_sound:play()
    end
    
    -- if it's dug
    if map[x][y] == 2 then
        move_allowed = true
    end
    
    -- if it's gold
    if map[x][y] == 3 then
        move_allowed = true
        
        
    end
    
    if move_allowed == true then
        -- move the player
        player_x = x
        player_y = y
        
        -- move monsters
        move_monsters()
    end
    
    if move_allowed == false then
        bump_sound:play();
    end
end

function monster_factory()
    mobs[#mobs+1] = {type = "greenie", x = 0, y = 0}
end

function move_monsters()
   for m=0, #mobs do
       
   end 
end

function dig_caves(n)
    
    for i=1, n do
        try_y = math.random(2,map_h-1)
        try_x = math.random(1,map_w-1)
    
        -- top row
        map[try_x-1][try_y-1] = 2
        map[try_x][try_y-1] = 2
        map[try_x+1][try_y-1] = 2
        -- middle row
        map[try_x-1][try_y] = 2
        map[try_x][try_y] = 2
        map[try_x+1][try_y] = 2
        -- bottom
        map[try_x-1][try_y+1] = 2
        map[try_x][try_y+1] = 2
        map[try_x+1][try_y+1] = 2
    end
    
end

function create_treasure(n)
    for i=0, n do
        
    end
end

function bury_ancient_treasure()
    
    goodspot = false
    
    while goodspot == false do
        try_y = math.random(2,map_h-1)
        try_x = math.random(1,map_w-1)
    
        if map[try_x][try_y] == 2 then
            goodspot = true
            treasure[#treasure+1] = {type = "gold", x = try_x, y = try_y, status="out"}
            map[try_x][try_y] = 3
        end
    end
    
end