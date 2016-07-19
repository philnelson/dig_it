function lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

function love.load()
    
    -- do we have saves?
    isDir = love.filesystem.isDirectory( "saves" )
    if isDir == true then
    
    else
        success = love.filesystem.createDirectory( "saves" )
    end
    
    -- do we have a cemetery?
    isFile = love.filesystem.isFile( "cemetery.txt" )
    
    if isFile == true then
        
    else
        success = love.filesystem.write( "cemetery.txt", "{}" )
    end

    math.randomseed( os.time() )
    math.randomseed( os.time() )
    math.randomseed( os.time() )
    
    first_cave_names = love.filesystem.read( "assets/fnames.txt" )
    last_cave_names = love.filesystem.read( "assets/lnames.txt" )
    
    first_names = lines(first_cave_names)
    last_names = lines(last_cave_names)
    
    main_font = love.graphics.newFont("assets/uni0553.ttf", 40)
    sub_font = love.graphics.newFont("assets/uni0553.ttf", 20)
    love.graphics.setFont(main_font)
    
    dig_sound = love.audio.newSource("assets/dig_normal.wav", "static")
    land_sound = love.audio.newSource("assets/plop.wav", "static")
    bump_sound = love.audio.newSource("assets/bump.wav", "static")
    gold_get_sound = love.audio.newSource("assets/gold_get.wav", "static")
    exit_sound = love.audio.newSource("assets/exit.wav", "static")
    slash_sound = love.audio.newSource("assets/slash.wav", "static")
    
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
    map_danger = 1
    map_world_x = 0
    map_world_y = 0
    
    set_up_map(5,0,2,map_danger, 0)
    
    mode = "title"
    
    game_state = {death_by = false, fall_start = false, damage_log = {}, travel_direction = nil}
    
    -- TODO make treasure become "damaged" when it drops a tile
end

function love.draw()

    draw_map()

    draw_treasure()

    -- exit
    --love.graphics.setColor(90, 90, 90)
    --love.graphics.rectangle( 'fill', map_x+(exit_x*tile_w), map_y+(exit_y*tile_h),  tile_w, tile_h)

    -- mobs
    draw_mobs()

	love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(sub_font)
    if player.hp >= 2 then
        love.graphics.print("you are fine", 0, 0)
    elseif player.hp == 1 then
        love.graphics.print("you are hurt", 0, 0)
    elseif player.hp == 0 then
        love.graphics.print("you are dead", 0, 0)
    end

    love.graphics.print("in " .. map_name, 0, 30)

    love.graphics.setFont(main_font)
    love.graphics.print("$" .. player.gold, 320, 0)

    -- player
    love.graphics.rectangle( 'fill', player.x_display, player.y_display, spriteWidth, spriteHeight )

    if player.hp == 1 then
        draw_hurt()
    end

    if mode == "title" then
        draw_title_screen()
    end

    if mode == "exiting" then
        draw_exit_modal()
    end

    if mode == "gameover" then
       draw_gameover_modal() 
    end

    if mode == "next_room" then
       draw_next_room_modal() 
    end

    
end

function draw_title_screen()
    
    love.graphics.setColor(0,0,0, 220)
    love.graphics.rectangle( 'fill', 0,0, 440, 800 )
    
    love.graphics.setColor(255,255,255)
    love.graphics.print("DIG_IT!", 10, 100)
    love.graphics.setFont(sub_font)
    love.graphics.print("an infinitely generated digging game", 10, 150)
    
    love.graphics.print("* you're the white square.", 10, 450)
    love.graphics.print("* dig down to get treasure!", 10, 480)
    love.graphics.print("* leave the greenies alone and", 10, 510)
    love.graphics.print("they won't hurt you.", 10, 540)
    love.graphics.print("* don't fall more than 2 spaces!!", 10, 570)
    love.graphics.print("* Go to new sections of cave by", 10, 600)
    love.graphics.print("walking beyond the screen edge", 10, 630)
    
    love.graphics.print("an extrafuture game by @philnelson", 30, 760)
    
    
    
    love.graphics.print("press enter to play", 110, 300)
end

function draw_mobs()
    for i=1, #mobs do
        if mobs[i].status == "fine" then
            love.graphics.setColor(17, 214, 99)
            love.graphics.polygon( 'fill', map_x+(mobs[i].x*tile_w), map_y+(mobs[i].y*tile_h)+(tile_h), map_x+(mobs[i].x*tile_w)+tile_w, map_y+(mobs[i].y*tile_h), map_x+(mobs[i].x*tile_w)+tile_w, map_y+(mobs[i].y*tile_h)+tile_h )
            --love.graphics.rectangle( 'fill', map_x+(mobs[i].x*tile_w), map_y+(mobs[i].y*tile_h),  tile_w, tile_h)
        else
            
        end
    end
end

function hurt_player(n, reason)
    
    game_state.death_by = reason
    
    total_damage = n
    
    if reason == "greenie" then
        slash_sound:play()
        table.insert(game_state.damage_log,"greenie")
        total_damage = 1
    end
    
    if reason == "falling" then
        table.insert(game_state.damage_log,"falling")
    end
    
    player.hp = player.hp - total_damage

    if player.hp == 0 then
        mode = "gameover"
        save_death()
    end
end

function does_collide_with_monster(x,y)
    
    collides = false
    
    for i=1, #mobs do
        if mobs[i].status == "fine" then
            if mobs[i].x == x then
                if mobs[i].y == y then
                   collides = true 
                end
            end
        end
    end
    
    return collides
end

function love.update(dt)
    
    if player.status == "fine" then
        player.x_display = player.x*spriteWidth
        player.y_display = player.y*spriteHeight+map_y
    end
    
    if player.falling == true then
        
        if game_state.fall_start == false then
            game_state.fall_start = { x = player.x, y = player.y }
        end
        
       player.y = player.y+1
       
       if map[player.x][player.y+1] == 0 then
          post_move_checks()
          
          if game_state.fall_start ~= false then
              if (player.y - game_state.fall_start.y) > 2 then
                  hurt_player(1,"falling")
              end
          end
          
          player.falling = false
          land_sound:play()
          game_state.fall_start = false
       end
       
       if player.y == map_h then
           post_move_checks()
           player.falling = false
           
           hurt_player(1,"falling")
           
           land_sound:play()
           game_state.fall_start = false
       end
    end
    
        for i=1, #mobs do
            if mobs[i].status == "falling" then
                mobs[i].y = mobs[i].y+1
            
                if mobs[i].x == player.x and mobs[i].y == player.y then
                    hurt_player(1, mobs[i].type)
                end
       
                if map[mobs[i].x][mobs[i].y+1] == 0 then
                   mobs[i].status = "fine"
                   land_sound:play()
                end
       
                if mobs[i].y == map_h then
                    mobs[i].status = "fine"
                    land_sound:play()
                end
            end
        end
    
    if treasure ~= nil then
        for i=1, #treasure do
            if map[treasure[i].x][treasure[i].y+1] == 2 then
                treasure[i].y = treasure[i].y+1
               --treasure[i].status = "fine"
               --land_sound:play()
               if treasure[i].x == player.x and treasure[i].y == player.y then
                   get_gold(25, i)
               end
            end
   
            if treasure[i].y == map_h then
                --treasure[i].status = "fine"
                --land_sound:play()
            end
        end
    end
    
end

function get_gold(num, id)
    player.gold = player.gold + 25
    treasure[id].status = "gotten"
    gold_get_sound:play()
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
            love.graphics.setColor(64, 40, 5)
            love.graphics.rectangle( 'fill', map_x+(x*tile_w), map_y+(y*tile_h),  tile_w, tile_h)
        end

            love.graphics.setColor(255, 255, 255)
            --love.graphics.print(x .. ", " .. y, map_x+(x*tile_w), map_y+(y*tile_h))
        end
    end
end

function draw_treasure()
    for i=1, #treasure do
        if treasure[i].status == "out" then
            love.graphics.setColor(214, 219, 46)
            love.graphics.rectangle( 'fill', map_x+(treasure[i].x*tile_w), map_y+(treasure[i].y*tile_h),  tile_w, tile_h)
        else
        
        end
    end 
end

function draw_hurt()
    love.graphics.setColor(214, 17, 17,100)
    love.graphics.rectangle( 'fill', 0, 0,  440, 800)
end

function love.keypressed(key)

   if key == "escape" then
      love.event.quit()
   end
   
   if mode == "gameover" then
       
       if key == "y" then
          map_world_x = 0
          map_world_y = 0
          set_up_map(5,0,2, 1, 0)
          mode = "map"
       end
       
       if key == "n" then
          love.event.quit()
       end
       
    elseif mode == "title" then
        
        if key == "return" then
           mode="map"
        end
    
    elseif mode == "next_room" then
        
        if key == "y" then
            
            save_map()
            
            if game_state.travel_direction == "west" then
                start_x = 10
                start_y = player.y
                map_world_x = map_world_x - 1
            end
            
            if game_state.travel_direction == "east" then
                start_x = 0
                start_y = player.y
                map_world_x = map_world_x + 1
            end
            
            if game_state.travel_direction == "south" then
                start_x = player.x
                start_y = 0
                map_world_y = map_world_y - 1
            end
            
            success = love.filesystem.read( 'saves/' .. map_world_x .. map_world_y .. '.txt')
            
            print("loading " .. map_world_x .. ", " .. map_world_y)
            
            if success == nil then
                set_up_map(start_x, start_y, player.hp, 1, player.gold)
            else
                load_map(map_world_x, map_world_y, start_x, start_y)
            end
           
           mode = "map"
        end
        
        if key == "n" then
           mode = "map"
        end
       
    elseif mode == "map" then
   
       if player.hp == 0 then
   
        else
   
           if key == "down" then
       
               if player.y + 1 == map_h+1 then
                   game_state.travel_direction = "south"
                   mode = "next_room"
               else
                  move_player(player.x, player.y + 1) 
          
               end
       
           end
   
           if key == "up" then
               -- can't dig up
           end
   
           if key == "left" then
               if player.x - 1 < 0 then
                   game_state.travel_direction = "west"
                   mode = "next_room"
               else
                   move_player(player.x - 1, player.y)
               end
           end
   
           if key == "right" then
               if player.x + 1 == map_w+1 then
                   game_state.travel_direction = "east"
                   mode = "next_room"
               else
                   move_player(player.x + 1, player.y)
               end
           end
       end
   end
end

function save_map()
    name = map_name
    map_data = map
    treasure_data = treasure
    mob_data = mobs
    
    save_data = {v=1, name=name, map=map_data, treasure=treasure_data, mobs=mob_data}
    
    success = love.filesystem.write( 'saves/' .. map_world_x .. map_world_y .. '.txt', table.tostring(save_data)) 
end

function save_death()
    
    local save_file, len = love.filesystem.read('cemetery.txt')
    
    if save_file == nil then
        print("no cemetery file found")
    else
        print(save_file)
        loadstring("cemetery_data=" .. save_file)()
    
        data = {death_by = game_state.death_by, steps = player.steps, date = os.time(), room = {x = map_world_x, y = map_world_y}}
        
        table.insert(cemetery_data, data)
    
        success, errormsg = love.filesystem.write( "cemetery.txt", table.tostring(cemetery_data))
    
        if errormsg then
           print("Couldn't save death and score.")
        end
    end
end

function move_player(x,y)
    if pre_move_checks(x,y) == true then

        -- move the player
        player.x = x
        player.y = y
        
        player.steps = player.steps + 1
        
        -- move monsters
        move_monsters()
        
        post_move_checks(player.x, player.y)
    end
end

-- this takes in the SUGGESTED new x,y pos for the player based on the user input
function pre_move_checks(x,y)
    
    move_allowed = false
    
    if does_collide_with_monster(x,y) == true then
        -- you get hit by a monster and get hurt
        hurt_player(1, "greenie")
    else
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
    end
    
    return move_allowed
end

function is_exit_move(start_x, start_y, end_x, end_y)
    
    exit_move = false
    
    if end_x == 0 then
        print("ding")
    end
    
end

function post_move_checks(x,y)
    
    if map[player.x][player.y+1] == 2 then
         player.falling = true
    end
    
    -- treasure check
    for i=1, #treasure do
        if treasure[i].x == player.x then
            if treasure[i].y == player.y then
                if treasure[i].status == "out" then
                    -- get that treasure son
                    get_gold(25,i)
                    --map[treasure[i].x][treasure[i].y] = 2
                end
            end
        end
    end
end

function monster_factory(n)
    
    n = math.random(1, n)
    
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
    
        mobs[#mobs+1] = {type = "greenie", x = try_x, y = try_y, status="fine", hp = 2}
    end
end

function move_monsters()
   for i=1, #mobs do
       
       direction = math.random(0,1)
       try_y = mobs[i].y
       
       move_allowed = false
       
       if direction == 0 then
           
           try_x = mobs[i].x-1
           
           if try_x > 0 then
               if map[try_x][try_y] == 2 then
                   move_allowed = true
               end
           end
       else
           try_x = mobs[i].x+1
           if try_x < map_w then
               if map[try_x][try_y] == 2 then
                   move_allowed = true
               end
           end
       end
       
       if move_allowed == true then
           if does_collide_with_monster(try_x, try_y) == false then
               mobs[i].x = try_x
           end
       end
       
       if map[mobs[i].x][mobs[i].y+1] == 2 then
            mobs[i].status = "falling"
       end
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

function draw_next_room_modal()
    
    love.graphics.setColor(0,0,0, 220)
    love.graphics.rectangle( 'fill', 0,0, 440, 800 )
    
    love.graphics.setColor(255,255,255)
    love.graphics.print("Would you like to", 10, 100)
    love.graphics.print("travel " .. game_state.travel_direction, 10, 150)
    
    love.graphics.print("(Y/N)", 150, 300)
    
end

function draw_gameover_modal()
    
    love.graphics.setColor(0,0,0, 220)
    love.graphics.rectangle( 'fill', 0,0, 440, 800 )
    
    love.graphics.setColor(255,255,255)
    love.graphics.print("WOW! You dead!", 10, 100)
    love.graphics.print("reincarnate?", 10, 150)
    
    love.graphics.print("death by " .. game_state.death_by, 10, 500)
    
    if game_state.death_by == "greenie" then
        love.graphics.print("it wasn't anyones", 10, 550)
        love.graphics.print("fault, i guess", 10, 600)
    end
    
    if game_state.death_by == "falling" then
        love.graphics.print("maybe next life", 10, 550)
        love.graphics.print("you'll look first", 10, 600)
    end
    
    
    love.graphics.print("(Y/N)", 150, 300)
    
end

function set_up_map(start_x, start_y, player_hp, danger, gold)
    
    -- init player
    player = {hp = player_hp,x = start_x, y = start_y, status = "fine", x_display=0, y_display = 0, gold = gold, falling = false, steps = 0}

    player_fall_start = {}
    player_fall_end = {}

    -- set up player display after player class is initialized
    player.x_display = player.x*spriteWidth
    player.y_display = player.y*spriteHeight+map_y
    
    success = love.filesystem.read( 'saves/' .. map_world_x .. map_world_y .. '.txt')
    
    print("loading " .. map_world_x .. ", " .. map_world_y)
    
    if success ~= nil then
        load_map(map_world_x, map_world_y, start_x, start_y)
    else
    
        map_name = "the " .. first_names[math.random(1,#first_names)] .. " " .. last_names[math.random(1,#last_names)]
    
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
        dig_caves(math.random(2,8))
        bury_ancient_treasure(math.random(1,4))
        place_exit()
    
        mobs = {}
    
        if map_danger < 3 then
            monster_factory(3)
        else
            monster_factory(6)
        end
    
        -- dig out the player's space
        map[player.x][player.y] = 2
    
        save_map()
    end
end

function load_map(x,y,start_x, start_y)
    
    local save_file, len = love.filesystem.read('saves/' .. x .. y .. '.txt')
    
    if save_file == nil then
        print("no save file found for " .. x .. ", " .. y)
    else
    
        
        loadstring("save_file_data=" .. save_file)()
        print(save_file_data)
        
        treasure = save_file_data.treasure
        mobs = save_file_data.mobs
        map = save_file_data.map
        map_name = save_file_data.name
        
        player.x = start_x
        player.y = start_y
        
        map[player.x][player.y] = 2
    end
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function loadTable(data)
   local table = {}
   local f = assert(loadstring(data))
   setfenv(f, table)
   f()
   return table
end