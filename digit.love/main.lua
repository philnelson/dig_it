function love.load()
    math.randomseed( os.time() )
    math.randomseed( os.time() )
    math.randomseed( os.time() )
    
    main_font = love.graphics.newFont("assets/uni0553.ttf", 40)
    love.graphics.setFont(main_font)
    
    dig_sound = love.audio.newSource("assets/dig_normal.wav", "static")
    land_sound = love.audio.newSource("assets/plop.wav", "static")
    bump_sound = love.audio.newSource("assets/bump.wav", "static")
    gold_get_sound = love.audio.newSource("assets/gold_get.wav", "static")
    exit_sound = love.audio.newSource("assets/exit.wav", "static")
    
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
    
    set_up_map()
    
    -- TODO make treasure become "damaged" when it drops a tile
end

function love.draw()
    draw_map()
    
    for i=1, #treasure do
        if treasure[i].status == "out" then
            love.graphics.setColor(214, 219, 46)
            love.graphics.rectangle( 'fill', map_x+(treasure[i].x*tile_w), map_y+(treasure[i].y*tile_h),  tile_w, tile_h)
        else
            
        end
    end
    
    -- exit
    love.graphics.setColor(90, 90, 90)
    love.graphics.rectangle( 'fill', map_x+(exit_x*tile_w), map_y+(exit_y*tile_h),  tile_w, tile_h)
    
    -- mobs
    for i=1, #mobs do
        if mobs[i].status == "alive" then
            love.graphics.setColor(17, 214, 99)
            love.graphics.rectangle( 'fill', map_x+(mobs[i].x*tile_w), map_y+(mobs[i].y*tile_h),  tile_w, tile_h)
        else
            
        end
    end
    
	love.graphics.setColor(255, 255, 255)
    love.graphics.print("you are " .. player.status, 0, 0)
    love.graphics.print("$" .. player.gold, 320, 0)
    
    -- player
    love.graphics.rectangle( 'fill', player.x_display, player.y_display, spriteWidth, spriteHeight )
    
    
end

function love.update(dt)
    
    if player.status == "fine" then
        player.x_display = player.x*spriteWidth
        player.y_display = player.y*spriteHeight+map_y
    elseif player.status == "falling" then
       player.y = player.y+1
       
       if map[player.x][player.y+1] == 0 then
          post_move_checks()
          player.status = "fine"
          land_sound:play()
       end
       
       if player.y == map_h then
           post_move_checks()
           player.status = "fine"
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
       
       if player.y + 1 == map_h+1 then
           
       else
          move_player(player.x, player.y + 1) 
          
       end
       
       if map[player.x][player.y+1] == 2 then
            player.status = "falling"
       end
       
   end
   
   if key == "up" then
       if player.y - 1 < 0 then
       
       elseif map[player.x][player.y - 1] == 2 then
           
       else
           move_player(player.x, player.y - 1)
       end
       
       if map[player.x][player.y+1] == 2 then
            player.status = "falling"
       end
   end
   
   if key == "left" then
       if player.x - 1 < 0 then
       
       else
           move_player(player.x - 1, player.y)
       end
       
       if map[player.x][player.y+1] == 2 then
            player.status = "falling"
       end
   end
   
   if key == "right" then
       if player.x + 1 == map_w+1 then
           
       else
           move_player(player.x + 1, player.y)
       end
       
       if map[player.x][player.y+1] == 2 then
            player.status = "falling"
       end
   end
   
end

function move_player(x,y)
    if pre_move_checks(x,y) == true then
        -- move the player
        player.x = x
        player.y = y
        
        -- move monsters
        move_monsters()
        
        post_move_checks(player.x, player.y)
    end
end

-- this takes in the SUGGESTED new x,y pos for the player based on the user input
function pre_move_checks(x,y)
    
    move_allowed = false
    
    --print(x .. ", " .. y)
    --print(map[x][y])
    
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
    
    -- if it's an exit
    if map[x][y] == 3 then
        move_allowed = true
    end
    
    -- can't move'
    if move_allowed == false then
        bump_sound:play();
    end
    
    return move_allowed
end

function post_move_checks(x,y)
    
    -- treasure check
    for i=1, #treasure do
        if treasure[i].x == player.x then
            if treasure[i].y == player.y then
                if treasure[i].status == "out" then
                    -- get that treasure son
                    treasure[i].status = "gotten"
                    player.gold = player.gold + 25
                    gold_get_sound:play()
                    --map[treasure[i].x][treasure[i].y] = 2
                end
            end
        end
    end
end

function monster_factory(n)
    
    for i=0, n do
        goodspot = false
        while goodspot == false do
            try_y = math.random(2,map_h-1)
            try_x = math.random(1,map_w-1)
    
            -- is the space dirt?
            if map[try_x][try_y] == 2 then
                -- is there "floor" underneath it?
                if map[try_x][try_y+1] == 0 then
                    if #mobs > 0 then
                        for m=1, #mobs do
                            if mobs[m][x] ~= try_x then
                                if mobs[m][y] ~= try_y then
                                    goodspot = true
                                end
                            end
                        end
                    else
                        goodspot = true
                    end
                end
            end
        end
    
        mobs[#mobs+1] = {type = "greenie", x = try_x, y = try_y, status="alive"}
    end
end

function move_monsters()
   for i=1, #mobs do
       mobs[i].x = mobs[i].x-1
   end 
end

function dig_caves(n)
    
    cave_w = 4
    cave_h = 3
    
    for i=1, n do
        try_y = math.random(3,map_h-2)
        try_x = math.random(2,map_w-2)
    
        -- top row
        map[try_x-1][try_y-1] = 2
        map[try_x][try_y-1] = 2
        map[try_x+1][try_y-1] = 2
        map[try_x+2][try_y-1] = 2
        -- middle row
        map[try_x-1][try_y] = 2
        map[try_x][try_y] = 2
        map[try_x+1][try_y] = 2
        map[try_x+2][try_y] = 2
        -- bottom
        map[try_x-1][try_y+1] = 2
        map[try_x][try_y+1] = 2
        map[try_x+1][try_y+1] = 2
        map[try_x+2][try_y+1] = 2
    end
    
end

function create_treasure(n)
    for i=0, n do
        
    end
end

function bury_ancient_treasure(n)
    
    for i=1, n do
        goodspot = false
        while goodspot == false do
            try_y = math.random(2,map_h-1)
            try_x = math.random(1,map_w-1)
        
            -- is the space dug out?
            if map[try_x][try_y] == 2 then
                -- is there "floor" underneath it?
                if map[try_x][try_y+1] == 0 then
                    goodspot = true
                    treasure[#treasure+1] = {type = "gold", x = try_x, y = try_y, status="out"}
                    --map[try_x][try_y] = 3
                end
            end
        end
    end
    
end

function place_exit()
    goodspot = false
    while goodspot == false do
        try_y = math.random(2,map_h-1)
        try_x = math.random(1,map_w-1)
    
        -- is the space dirt?
        if map[try_x][try_y] == 0 then
            -- is there "floor" underneath it?
            if map[try_x][try_y+1] == 0 then
                goodspot = true
                exit_x = try_x
                exit_y = try_y
                map[try_x][try_y] = 2
            end
        end
    end
end

function set_up_map()
    tiles = {}
    treasure = {}
    map={}
    
    -- build out map
    for x=0, map_w do
        map[x] = {}
       for y=0, map_h do
          map[x][y] = 0
       end
    end
    
    -- set up elements
    dig_caves(math.random(1,6))
    bury_ancient_treasure(math.random(1,4))
    place_exit()
    
    mobs = {}
    monster_factory(5)
    
    -- init player
    player = {x = 5, y = 0, status = "fine", x_display=0, y_display = 0, gold = 0}
    
    player_fall_start = {}
    player_fall_end = {}
    
    -- set up player display after player class is initialized
    player.x_display = player.x*spriteWidth
    player.y_display = player.y*spriteHeight+map_y
    
    -- dig out the player's space
    map[player.x][player.y] = 2
end