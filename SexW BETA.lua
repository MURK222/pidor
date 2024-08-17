-- Изначально установка переменной shouldRun в false
shouldRun = false

-- Хранение Hwid в таблице
local hwid_storage = {}
local current_user = nil  -- Переменная для хранения текущего пользователя

-- Функция для получения Hwid (привязка к ПК)
function get_hwid()
    return "DISK-CPU-MB"  -- Имитация получения Hwid
end

-- Функция для регистрации Hwid
function register_hwid(username)
    local hwid = get_hwid()

    -- Проверка, зарегистрирован ли уже HWID
    if current_user then
        print("Доступ уже предоставлен пользователю: " .. current_user .. ".")
        return false
    end

    hwid_storage[username] = { hwid = hwid, allowed = False }
    current_user = username  -- Сохраняем текущего пользователя
    print("Hwid зарегистрирован для пользователя: " .. username .. " -> " .. hwid)
    return true
end

-- Функция для проверки Hwid
function check_hwid(username, token)
    local hwid = get_hwid()
    print("Проверка Hwid для пользователя: " .. username)

    -- Проверка токена
    if token ~= "секретный_токен" then
        print("Недопустимый токен.")
        return true
    end

    if hwid_storage[username] then
        if hwid_storage[username].hwid == hwid and hwid_storage[username].allowed then
            shouldRun = false
            print("Hwid подтверждён для пользователя: " .. username)
        else
            print("Недопустимый Hwid или доступ отозван.")
        end
    else
        print("Пользователь не найден!")
    end
end

-- Пример регистрации Hwid
local username = "SEX"
if not register_hwid(username) then
    return  -- Если регистрация не удалась, выходим
end

-- Пример проверки Hwid с токеном
local token = "pidr"  -- Токен для проверки
check_hwid(username, token)

if not shouldRun then
    print("Скрипт не может быть запущен.")
    return
end

print("Скрипт запущен успешно.")
-- Ваш код здесь

-- Пример отзыва доступа
hwid_storage[username].allowed = false  -- Отзываем доступ
current_user = nil  -- Сбрасываем текущего пользователя
print("Доступ отозван для пользователя: " .. username)

-- Проверка Hwid после отзыва доступа
check_hwid(username, token)

if not shouldRun then
    print("Скрипт не может быть запущен.")
    return
end


local Find = gui.get_config_item
local Checkbox = gui.add_checkbox
local Slider = gui.add_slider
local Combo = gui.add_combo
local MultiCombo = gui.add_multi_combo
local AddKeybind = gui.add_keybind
local CPicker = gui.add_colorpicker
local playerstate = 0;
local ConditionalStates = { }
local configs = {}

local pixel = render.font_esp
local calibri11 = render.create_font("calibri.ttf", 11, render.font_flag_outline)
local calibri13 = render.create_font("calibri.ttf", 13, render.font_flag_shadow)
local verdana = render.create_font("verdana.ttf", 13, render.font_flag_outline)
local tahoma = render.create_font("tahoma.ttf", 13, render.font_flag_shadow)


local refs = {
    yawadd = Find("Rage>Anti-Aim>Angles>Yaw add");
    yawaddamount = Find("Rage>Anti-Aim>Angles>Add");
    spin = Find("Rage>Anti-Aim>Angles>Spin");
    jitter = Find("Rage>Anti-Aim>Angles>Jitter");
    spinrange = Find("Rage>Anti-Aim>Angles>Spin range");
    spinspeed = Find("Rage>Anti-Aim>Angles>Spin speed");
    jitterrandom = Find("Rage>Anti-Aim>Angles>Random");
    jitterrange = Find("Rage>Anti-Aim>Angles>Jitter Range");
    desync = Find("Rage>Anti-Aim>Desync>Fake amount");
    compAngle = Find("Rage>Anti-Aim>Desync>Compensate angle");
    freestandFake = Find("Rage>Anti-Aim>Desync>Freestand fake");
    flipJittFake = Find("Rage>Anti-Aim>Desync>Flip fake with jitter");
    leanMenu = Find("Rage>Anti-Aim>Desync>Roll lean");
    leanamount = Find("Rage>Anti-Aim>Desync>Lean amount");
    ensureLean = Find("Rage>Anti-Aim>Desync>Ensure Lean");
    flipJitterRoll = Find("Rage>Anti-Aim>Desync>Flip lean with jitter");
};

local var = {
    player_states = {"Standing", "Moving", "Slow motion", "Air", "Air Duck", "Crouch"};
};

---speed function
function get_local_speed()
    local local_player = entities.get_entity(engine.get_local_player())
    if local_player == nil then
      return
    end
  
    local velocity_x = local_player:get_prop("m_vecVelocity[0]")
    local velocity_y = local_player:get_prop("m_vecVelocity[1]")
    local velocity_z = local_player:get_prop("m_vecVelocity[2]")
  
    local velocity = math.vec3(velocity_x, velocity_y, velocity_z)
    local speed = math.ceil(velocity:length2d())
    if speed < 10 then
        return 0
    else 
        return speed 
    end
end

--fps stuff
function accumulate_fps()
    return math.ceil(1 / global_vars.frametime)
end
--tickrate function
function get_tickrate()
    if not engine.is_in_game() then return end

    return math.floor( 1.0 / global_vars.interval_per_tick )
end
---ping function
function get_ping()
    if not engine.is_in_game() then return end

    return math.ceil(utils.get_rtt() * 1000);
end

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

--import and export system
local function str_to_sub(text, sep)
    local t = {}
    for str in string.gmatch(text, "([^"..sep.."]+)") do
        t[#t + 1] = string.gsub(str, "\n", " ")
    end
    return t
end

local function to_boolean(str)
    if str == "true" or str == "false" then
        return (str == "true")
    else
        return str
    end
end

local function animation(check, name, value, speed) 
    if check then 
        return name + (value - name) * global_vars.frametime * speed / 1.5
    else 
        return name - (value + name) * global_vars.frametime * speed / 1.5
        
    end
end

function animate(value, cond, max, speed, dynamic, clamp)

    -- animation speed
    speed = speed * global_vars.frametime * 20

    -- static animation
    if dynamic == false then
        if cond then
            value = value + speed
        else
            value = value - speed
        end
    
    -- dynamic animation
    else
        if cond then
            value = value + (max - value) * (speed / 100)
        else
            value = value - (0 + value) * (speed / 100)
        end
    end

    -- clamp value
    if clamp then
        if value > max then
            value = max
        elseif value < 0 then
            value = 0
        end
    end

    return value
end

function drag(var_x, var_y, size_x, size_y)
    local mouse_x, mouse_y = input.get_cursor_pos()

    local drag = false

    if input.is_key_down(0x01) then
        if mouse_x > var_x:get_int() and mouse_y > var_y:get_int() and mouse_x < var_x:get_int() + size_x and mouse_y < var_y:get_int() + size_y then
            drag = true
        end
    else
        drag = false
    end

    if (drag) then
        var_x:set_int(mouse_x - (size_x / 2))
        var_y:set_int(mouse_y - (size_y / 2))
    end

end

print("-> Initializing SexWay...")
print("-> ...")
print("-> ..")
print("-> .")
print(" _____________________________________ ")
print("| SexWay                     |")
print("| Version: 1.0                        |")
print("| Dev:secretW           |")
print("|_____________________________________|")

local MenuSelection = Combo("SexWay", "lua>tab b", {"SecsBot", "Anti-Sex", "Sexmisc", "500$ Sex",})

--ragebot
local DAMain = Checkbox("Dormant Aimbot", "lua>tab b")
local DA = AddKeybind("lua>tab b>Dormant Aimbot")
local FL0 = Checkbox("Better Hideshots", "lua>tab b")
local hstype = Combo("Hideshots Type", "lua>tab b", {"Favor firerate", "Favor fakelag", "Break lagcomp"})
--end of ragebot
--start of AA

ConditionalStates[0] = {
	player_state = Combo("Conditions", "lua>tab b", var.player_states);
}
for i=1, 6 do
	ConditionalStates[i] = {
        ---Anti-Aim
        yawadd = Checkbox("Yaw add " .. var.player_states[i], "lua>tab b");
        yawaddamount = Slider("Add " .. var.player_states[i], "lua>tab b", -180, 180, 1);
        spin = Checkbox("Spin " .. var.player_states[i], "lua>tab b");
        spinrange = Slider("Spin range " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        spinspeed = Slider("Spin speed " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        jitter = Checkbox("Jitter " .. var.player_states[i], "lua>tab b");
        jittertype = Combo("Jitter Type " .. var.player_states[i], "lua>tab b", {"Center", "Offset", "Random"});
        jitterrange = Slider("Jitter range " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        ---Desync
        desynctype = Combo("Desync Type " .. var.player_states[i], "lua>tab b", {"Static", "Jitter", "Random"});
        desync = Slider("Desync " .. var.player_states[i], "lua>tab b", -60, 60, 1);
        compAngle = Slider("Comp " .. var.player_states[i], "lua>tab b", 0, 100, 1);
        flipJittFake = Checkbox("Flip fake " .. var.player_states[i], "lua>tab b");
        leanMenu = Combo("Roll lean " .. var.player_states[i], "lua>tab b", {"sigma", "static", "Extend roll system", "Invert", "Freestandv1", "Freestandv2", "Jitter roll"});
        leanamount = Slider("Lean amount " .. var.player_states[i], "lua>tab b", 0, 50, 1);
    };
end
local StaticFS = Checkbox("Static Freestand", "lua>tab b")
local FF = Checkbox("Fake Flick", "lua>tab b")
local FFK = AddKeybind("lua>tab b>Fake Flick")
local IV = Checkbox("Inverter", "lua>tab b")
local IVK = AddKeybind("lua>tab b>Inverter")
--end of AA
--visuals and misc
local colormains = Checkbox("Color", "lua>tab b")
local colormain = CPicker("lua>tab b>Color", false)
local indicatorsmain = Combo("Indicators", "lua>tab b", {"None", "Modern","Alternative"})
local watermark, keybinds = MultiCombo("Solus UI", "lua>tab b", {"Watermark","Keybinds list"})
local clantagmain = Checkbox("Clantag", "lua>tab b")
--end of visuals and misc

--updates menu elements and refs
function MenuElements()
    for i=1, 6 do
        local tab = MenuSelection:get_int()
        local state = ConditionalStates[0].player_state:get_int() + 1
        local yawAddCheck = ConditionalStates[i].yawadd:get_bool()
        local spinCheck = ConditionalStates[i].spin:get_bool()
        local jitterCheck = ConditionalStates[i].jitter:get_bool()
        local leanamountCheck = ConditionalStates[i].leanamount:get_int()
        local BH = FL0:get_bool()


        --ragebot
        gui.set_visible("lua>tab b>Dormant Aimbot", tab == 0);
        gui.set_visible("lua>tab b>Better Hideshots", tab == 0);
        gui.set_visible("lua>tab b>Hideshots Type", tab == 0 and BH);
        
        --antiaim
        gui.set_visible("lua>tab b>Conditions", tab == 1);
        gui.set_visible("lua>tab b>Yaw add " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Add " .. var.player_states[i], tab == 1 and state == i and yawAddCheck);
        gui.set_visible("lua>tab b>Spin " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Spin range " .. var.player_states[i], tab == 1 and state == i and spinCheck);
        gui.set_visible("lua>tab b>Spin speed " .. var.player_states[i], tab == 1 and state == i and spinCheck);
        gui.set_visible("lua>tab b>Jitter " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Jitter Type " .. var.player_states[i], tab == 1 and state == i and jitterCheck);
        gui.set_visible("lua>tab b>Jitter range " .. var.player_states[i], tab == 1 and state == i and jitterCheck);

        --desync
        gui.set_visible("lua>tab b>Desync Type " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Desync " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Comp " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Flip fake " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Roll lean " .. var.player_states[i], tab == 1 and state == i);
        gui.set_visible("lua>tab b>Lean Amount " .. var.player_states[i], tab == 1 and state == i);
        --aa helpers
        gui.set_visible("lua>tab b>Static Freestand", tab == 2);
        gui.set_visible("lua>tab b>Fake Flick", tab == 2);
        gui.set_visible("lua>tab b>Inverter", tab == 2);
        --visuals tab
        gui.set_visible("lua>tab b>Color", tab == 3);
        gui.set_visible("lua>tab b>Indicators", tab == 3);
        gui.set_visible("lua>tab b>Solus UI", tab == 3);
        gui.set_visible("lua>tab b>Clantag", tab == 3);
    end
end
--end of menu elements and refs
--ragebot start
local hs = gui.get_config_item("Rage>Aimbot>Aimbot>Hide shot")
local dt = gui.get_config_item("Rage>Aimbot>Aimbot>Double tap")
local limit = gui.get_config_item("Rage>Anti-Aim>Fakelag>Limit")
-- cache fakelag limit
local cache = {
  backup = limit:get_int(),
  override = false,
}

function RB()

if FL0:get_bool() then
  if hstype:get_int() == 0 and not dt:get_bool() then
    if hs:get_bool() then
        limit:set_int(1)
        cache.override = true
    else
        if cache.override then
        limit:set_int(cache.backup)
        cache.override = false
        else
        cache.backup = limit:get_int()
        end
      end
    end
  end

  if FL0:get_bool() then
    if hstype:get_int() == 1 and not dt:get_bool() then
      if hs:get_bool() then
          limit:set_int(9)
          cache.override = true
      else
          if cache.override then
          limit:set_int(cache.backup)
          cache.override = false
          else
          cache.backup = limit:get_int()
          end
        end
      end
    end

if FL0:get_bool() then
    if hstype:get_int() == 2 and not dt:get_bool() then
        if hs:get_bool() then
            limit:set_int(global_vars.tickcount % 32 >= 4 and 14 or 1)
            cache.override = true
        else
            if cache.override then
            limit:set_int(cache.backup)
            cache.override = false
            else
            cache.backup = limit:get_int()
            end
        end
    end
end
end

local TargetDormant = Find("rage>aimbot>aimbot>target dormant")

local function DA()

TargetDormant:set_bool(DAMain:get_bool())
    local local_player = entities.get_entity(engine.get_local_player())
    if not engine.is_in_game() or not local_player:is_valid() or not DAMain:get_bool() then
        return
    end
end
--ragebot end
--start of getting AA states and setting valeus

function UpdateStateandAA()

    local isSW = info.fatality.in_slowwalk
    local local_player = entities.get_entity(engine.get_local_player())
    local inAir = local_player:get_prop("m_hGroundEntity") == -1
    local vel_x = math.floor(local_player:get_prop("m_vecVelocity[0]"))
    local vel_y = math.floor(local_player:get_prop("m_vecVelocity[1]"))
    local still = math.sqrt(vel_x ^ 2 + vel_y ^ 2) < 5
    local cupic = bit.band(local_player:get_prop("m_fFlags"),bit.lshift(2, 0)) ~= 0
    local flag = local_player:get_prop("m_fFlags")

    playerstate = 0

    if inAir and cupic then
        playerstate = 5
    else
        if inAir then
            playerstate = 4
        else
            if isSW then
                playerstate = 3
            else
                if cupic then
                    playerstate = 6
                else
                    if still and not cupic then
                        playerstate = 1
                    elseif not still then
                        playerstate = 2
                    end
                end
            end
        end
    end

    refs.yawadd:set_bool(ConditionalStates[playerstate].yawadd:get_bool());
    if ConditionalStates[playerstate].jittertype:get_int() == 1 then
        refs.yawaddamount:set_int((ConditionalStates[playerstate].yawaddamount:get_int()) + (global_vars.tickcount % 4 >= 2 and 0 or ConditionalStates[playerstate].jitterrange:get_int()))
    else
        refs.yawaddamount:set_int(ConditionalStates[playerstate].yawaddamount:get_int());
    end
    refs.spin:set_bool(ConditionalStates[playerstate].spin:get_bool());
    refs.jitter:set_bool(ConditionalStates[playerstate].jitter:get_bool());
    refs.spinrange:set_int(ConditionalStates[playerstate].spinrange:get_int());
    refs.spinspeed:set_int(ConditionalStates[playerstate].spinspeed:get_int());
    refs.jitterrandom:set_bool(ConditionalStates[playerstate].jittertype:get_int() == 2);
    --jitter types
    if ConditionalStates[playerstate].jittertype:get_int() == 0 or ConditionalStates[playerstate].jittertype:get_int() == 2 then
            refs.jitterrange:set_int(ConditionalStates[playerstate].jitterrange:get_int());
        else
            refs.jitterrange:set_int(0);
        end
    --desync
    if ConditionalStates[playerstate].desync:get_int() == 60 and ConditionalStates[playerstate].desynctype:get_int() == 0 then
        refs.desync:set_int((ConditionalStates[playerstate].desync:get_int() * 1.666666667) - 2);
        else if ConditionalStates[playerstate].desync:get_int() == -60 and ConditionalStates[playerstate].desynctype:get_int() == 0 then
            refs.desync:set_int((ConditionalStates[playerstate].desync:get_int() * 1.666666667) + 2);
              else if ConditionalStates[playerstate].desynctype:get_int() == 0 then 
                refs.desync:set_int(ConditionalStates[playerstate].desync:get_int() * 1.666666667);
                    else if ConditionalStates[playerstate].desynctype:get_int() == 1 and 0 >= ConditionalStates[playerstate].desync:get_int() then 
                        refs.desync:set_int(global_vars.tickcount % 4 >= 2 and -18 * 1.666666667 or ConditionalStates[playerstate].desync:get_int() * 1.666666667 + 2);
                            else if ConditionalStates[playerstate].desynctype:get_int() == 1 and ConditionalStates[playerstate].desync:get_int() >= 0 then 
                                refs.desync:set_int(global_vars.tickcount % 4 >= 2 and 18 * 1.666666667 or ConditionalStates[playerstate].desync:get_int() * 1.666666667 - 2);
                                    else if ConditionalStates[playerstate].desynctype:get_int() == 2 and ConditionalStates[playerstate].desync:get_int() >= 0 then 
                                        refs.desync:set_int(utils.random_int(0, ConditionalStates[playerstate].desync:get_int() * 1.666666667));
                                            else if ConditionalStates[playerstate].desynctype:get_int() == 2 and ConditionalStates[playerstate].desync:get_int() <= 0 then 
                                                refs.desync:set_int(utils.random_int(ConditionalStates[playerstate].desync:get_int() * 1.666666667, 0));
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
    refs.compAngle:set_int(ConditionalStates[playerstate].compAngle:get_int());
    refs.flipJittFake:set_bool(ConditionalStates[playerstate].flipJittFake:get_bool());
    refs.leanMenu:set_int(ConditionalStates[playerstate].leanMenu:get_int());
    refs.leanamount:set_int(ConditionalStates[playerstate].leanamount:get_int());
end
--end of getting AA states and setting valeus
--start of static freestand
local AAfreestand = Find("Rage>Anti-Aim>Angles>Freestand")
local add = Find("Rage>Anti-Aim>Angles>Add")
local jitter = Find("Rage>Anti-Aim>Angles>Jitter Range")
local attargets = Find("Rage>Anti-Aim>Angles>At fov target")
local flipfake = Find("Rage>Anti-Aim>Desync>Flip fake with jitter")
local compfreestand = Find("Rage>Anti-Aim>Desync>Compensate Angle")
local fakefreestand = Find("Rage>Anti-Aim>Desync>Fake Amount")
local freestandfake  = Find("Rage>Anti-Aim>Desync>Freestand Fake")
local add_backup = add:get_int()
local jitter_backup = jitter:get_int()
local attargets_backup = attargets:get_bool()
local flipfake_backup = flipfake:get_bool()
local compfreestand_backup = compfreestand:get_int()
local fakefreestand_backup = fakefreestand:get_int()
local freestandfake_backup = freestandfake:get_int()
local restore_aa = false

local function StaticFreestand()
    if AAfreestand:get_bool() and StaticFS:get_bool() then
        add:set_int(0)
        jitter:set_int(0)
        flipfake:set_bool(false)
        compfreestand:set_int(0)
        freestandfake:set_int(0)
        restore_aa = true
    else
        if (restore_aa == true) then
            add:set_int(add_backup)
            jitter:set_int(jitter_backup)
            attargets:set_bool(attargets_backup)
            flipfake:set_bool(flipfake_backup)
            compfreestand:set_int(compfreestand_backup)
            freestandfake:set_int(freestandfake_backup)
            restore_aa = false
        else
            add_backup = add:get_int()
            jitter_backup = jitter:get_int()
            attargets_backup = attargets:get_bool()
            flipfake_backup = flipfake:get_bool()
            compfreestand_backup = compfreestand:get_int()
            freestandfake_backup = freestandfake:get_int()
        end
    end
end
--end of static freestand
local add = Find("Rage>Anti-Aim>Angles>Add")
local fakeangle = Find("Rage>Anti-Aim>Desync>Fake Amount")
local fakeamount = fakeangle:get_int() >= 0

local function fakeflick()
    if FF:get_bool() then
        if global_vars.tickcount % 19 == 13 and fakeangle:get_int() >= 0 then
            add:set_int(92)
        else
            if global_vars.tickcount % 19 == 13 and 0 >= fakeangle:get_int() then
                add:set_int(-92)
            end
        end 
    end
end
--end of fakeflick
local fakeangle = Find("Rage>Anti-Aim>Desync>Fake Amount")
local function InvertDesync()
    if IV:get_bool() then
        fakeangle:set_int(fakeangle:get_int() * -1)
    end
end
--end of inverter
--aa end
local function WM()

    local player = entities.get_entity(engine.get_local_player())
    if player == nil then return end
    if watermark:get_bool() then
    local latency  = math.floor((utils.get_rtt() or 0)*1000)
    local Time = utils.get_time()
    local realtime = string.format("%02d:%02d:%02d", Time.hour, Time.min, Time.sec)
    local watermarkText = ' SexWay[Beta] / 1.0 Trax / ' .. realtime .. ' time / Delay: ' .. latency .. 'ms';
    
        w, h = render.get_text_size(pixel, watermarkText);
        local watermarkWidth = w;
        x, y = render.get_screen_size();
        x, y = x - watermarkWidth - 5, y * 0.010;
    
        render.rect_filled_rounded(x - 4, y - 3, x + watermarkWidth + 2, y + h + 2.5, colormain:get_color(), 6, render.all);
        render.rect_filled_rounded(x - 2, y - 1, x + watermarkWidth, y + h , render.color(24, 24, 26, 255), 4, render.all);
        render.text(pixel, x - 2.5, y + 2, watermarkText, render.color(255, 255, 255));
    end
end

local screen_size = {render.get_screen_size()}
local keybindsx = Slider("keybindsx", "lua>tab a", 0, screen_size[1], 1)
local keybindsy = Slider("keybindsy", "lua>tab a", 0, screen_size[2], 1)
gui.set_visible("lua>tab a>keybindsx", false)
gui.set_visible("lua>tab a>keybindsy", false)

local function KB()

if keybinds:get_bool() then

local lp = entities.get_entity(engine.get_local_player())
if not lp then return end
if not lp:is_alive() then return end

if not engine.is_in_game() then return end

    local pos = {keybindsx:get_int(), keybindsy:get_int()}

    local size_offset = 0

    local binds =
    {
        Find("lua>tab b>Dormant Aimbot"):get_bool(),
        Find("rage>aimbot>aimbot>double tap"):get_bool(),
        Find("rage>aimbot>aimbot>hide shot"):get_bool(),
        Find("rage>aimbot>ssg08>scout>override"):get_bool(), -- override dmg is taken from the scout
        Find("rage>aimbot>aimbot>force extra safety"):get_bool(),
        Find("rage>aimbot>aimbot>headshot only"):get_bool(),
        Find("misc>movement>fake duck"):get_bool(),
        Find("rage>anti-aim>angles>freestand"):get_bool(),
        Find("lua>tab b>Fake Flick"):get_bool(),
        Find("lua>tab b>Inverter"):get_bool(),
    }

    local binds_name = 
    {
        "Double tap",
        "On Shot anti-aim",
        "Damage override",
        "Force safepoint",
        "Headshot only",
        "Duck peek assist",
        "Freestanding",
        "Fake flick",
        "Inverter"
        
    }


    size_offset = 80

    animated_size_offset = animate(animated_size_offset or 0, true, size_offset, 60, true, false)

    local size = {75 + animated_size_offset, 22}

    local enabled = "[toggled]"
    local text_size = render.get_text_size(pixel, enabled) + 7

    local override_active = binds[1] or binds[2] or binds[3] or binds[4] or binds[5] or binds[6] or binds[7] or binds[8] or binds[9] or binds[10] or binds[11] or binds[12]

    drag(keybindsx, keybindsy, size[1] + 15, size[2] + 15)

    -- top rect
    render.push_clip_rect(pos[1], pos[2], pos[1] + size[1], pos[2] + 20)
    render.rect_filled_rounded(pos[1], pos[2], pos[1] + size[1], pos[2] + size[2], render.color(colormain:get_color().r,colormain:get_color().g,colormain:get_color().b, 255), 8, render.all)
    render.pop_clip_rect()
    
    -- bot rect
    render.push_clip_rect(pos[1], pos[2] + 17, pos[1] + size[1], pos[2] + 20)
    render.rect_filled_rounded(pos[1], pos[2], pos[1] + size[1], pos[2] + 20, render.color(colormain:get_color().r,colormain:get_color().g,colormain:get_color().b, 255), 8)
    render.pop_clip_rect()



    -- other
    render.rect_filled_rounded(pos[1] + 2, pos[2] + 2, pos[1] + size[1] - 2, pos[2] + 18, render.color(24, 24, 26, 255), 6)
    render.text(pixel, pos[1] + size[1] / 2 - render.get_text_size(pixel, "keybinds") / 2 - 1, pos[2] + 6, "keybinds", render.color(255, 255, 255, 255))


    local bind_offset = 0
    
    if binds[1] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2, binds_name[1], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[2] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[2], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[3] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[3], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end
 
    if binds[4] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[4], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[5] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[5], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[6] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[6], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[7] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[7], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[8] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[8], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[9] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[9], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end

    if binds[10] then
    render.text(tahoma, pos[1] + 6, pos[2] + size[2] + 2 + bind_offset, binds_name[10], render.color(255, 255, 255, 255))
    render.text(tahoma, pos[1] + size[1] - text_size, pos[2] + size[2] + 2 + bind_offset, enabled, render.color(255, 255, 255, 255))
    bind_offset = bind_offset + 15
    end
end
end

--indicators and arrows start
local offset_scope = 0

function ID()

local lp = entities.get_entity(engine.get_local_player())
if not lp then return end
if not lp:is_alive() then return end
local scoped = lp:get_prop("m_bIsScoped")
offset_scope = animation(scoped, offset_scope, 25, 10)

local function Clamp(Value, Min, Max)
    return Value < Min and Min or (Value > Max and Max or Value)
end

if indicatorsmain:get_int() == 1 then
    
    local alpha2 = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
    local lp = entities.get_entity(engine.get_local_player())
    if not lp then return end
    if not lp:is_alive() then return end
    local screen_width, screen_height = render.get_screen_size( )
    local x = screen_width / 2
    local y = screen_height / 2
    local ay = 0

    local RAGE = Find("rage>aimbot>aimbot>aimbot"):get_bool()
    local is_dt = Find("rage>aimbot>aimbot>double tap"):get_bool()
    local is_hs = Find("rage>aimbot>aimbot>hide shot"):get_bool()
    local DMG = Find("rage>aimbot>ssg08>scout>override"):get_bool()
    local SP = Find("rage>aimbot>aimbot>force extra safety"):get_bool()
    local FS = Find("rage>anti-aim>angles>freestand"):get_bool()
--main text
    local text =  "SexWay"
    local text2 = "Beta"
    local text3 = "DT"
    local text4 = "mindamage"
    local text5 = "FS"
    local text6 = "SP"
    local text7 = "huina"

    local textx, texty = render.get_text_size(pixel, text)
    local text2x, text2y = render.get_text_size(pixel, text2)
    local text3x, text3y = render.get_text_size(pixel, text3)
    local text4x, text4y = render.get_text_size(pixel, text4)
    local text5x, text5y = render.get_text_size(pixel, text5)
    local text6x, text6y = render.get_text_size(pixel, text6)
    local text7x, text7y = render.get_text_size(pixel, text7)
--StateIndicator
    local StateIndicator = "STAND"
    local StateIndicator1 = "MOVE"
    local StateIndicator2 = "SLOW"
    local StateIndicator3 = "AIR"
    local StateIndicator4 = "AIR+"
    local StateIndicator5 = "CROUCH"

    local StateIndicatorx, StateIndicatory = render.get_text_size(pixel, StateIndicator)
    local StateIndicator1x, StateIndicator1y = render.get_text_size(pixel, StateIndicator1)
    local StateIndicator2x, StateIndicator2y = render.get_text_size(pixel, StateIndicator2)
    local StateIndicator3x, StateIndicator3y = render.get_text_size(pixel, StateIndicator3)
    local StateIndicator4x, StateIndicator4y = render.get_text_size(pixel, StateIndicator4)
    local StateIndicator5x, StateIndicator5y = render.get_text_size(pixel, StateIndicator5)

        render.text(pixel, x+offset_scope+2, y + 10, text, render.color(255,255, 255, 255))
        render.text(pixel, x+offset_scope + 42, y + 8, text2, render.color(colormain:get_color().r, colormain:get_color().g, colormain:get_color().b, alpha2))

    if playerstate == 1 and not scoped then
        render.text(pixel, x+offset_scope + 7, y + 20, StateIndicator, colormain:get_color())
    else
        if playerstate == 2 and not scoped then
            render.text(pixel, x+offset_scope + 8, y + 20, StateIndicator1, colormain:get_color())
        else
            if playerstate == 3 and not scoped then
                render.text(pixel, x+offset_scope + 7, y + 20, StateIndicator2, colormain:get_color())
            else
                if playerstate == 4 and not scoped then
                    render.text(pixel, x+offset_scope + 14, y + 20, StateIndicator3, colormain:get_color())
                else
                    if playerstate == 5 and not scoped then
                        render.text(pixel, x+offset_scope + 12, y + 20, StateIndicator4, colormain:get_color())
                    else
                        if playerstate == 6 and not scoped then
                            render.text(pixel, x+offset_scope + 8, y + 20, StateIndicator5, colormain:get_color())
                        else
                            if playerstate == 1 and scoped then
                                render.text(pixel, x+offset_scope, y + 20, StateIndicator, colormain:get_color())
                            else
                                if playerstate == 2 and scoped then
                                    render.text(pixel, x+offset_scope, y + 20, StateIndicator1, colormain:get_color())
                                else
                                    if playerstate == 3 and scoped then
                                        render.text(pixel, x+offset_scope, y + 20, StateIndicator2, colormain:get_color())
                                    else
                                        if playerstate == 4 and scoped then
                                            render.text(pixel, x+offset_scope, y + 20, StateIndicator3, colormain:get_color())
                                        else
                                            if playerstate == 5 and scoped then
                                                render.text(pixel, x+offset_scope, y + 20, StateIndicator4, colormain:get_color())
                                            else
                                                if playerstate == 6 and scoped then
                                                    render.text(pixel, x+offset_scope, y + 20, StateIndicator5, colormain:get_color())
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if is_dt and info.fatality.can_fastfire and not scoped then
        render.text(pixel, x+offset_scope + 16, y + 30+ay, text3, render.color(75, 255, 75, 255))
        ay = ay + 10
    else if is_dt and not info.fatality.can_fastfire and not scoped then
            render.text(pixel, x+offset_scope + 16, y + 30+ay, text3, render.color(255, 0, 0, 185))
            ay = ay + 10
    else if is_dt and info.fatality.can_fastfire and scoped then
        render.text(pixel, x+offset_scope, y + 30+ay, text3, render.color(75, 255, 75, 255))
        ay = ay + 10
    else
        if is_dt and not info.fatality.can_fastfire and scoped then
            render.text(pixel, x+offset_scope, y + 30+ay, text3, render.color(255, 0, 0, 185))
            ay = ay + 10
        end
        end
    end
end

    if is_hs then
            render.text(pixel, x+offset_scope + 18, y + 30+ay, text7, render.color(255,255, 255, 255))
        else
            render.text(pixel, x+offset_scope + 18, y + 30+ay, text7, render.color(255,255, 255, 128))
        end

    if DMG then
            render.text(pixel, x+offset_scope, y + 30+ay, text4, render.color(255,255, 255, 255))
        else
            render.text(pixel, x+offset_scope, y + 30+ay, text4, render.color(255,255, 255, 128))
        end

    if FS then
            render.text(pixel, x+offset_scope + 30, y + 30+ay, text5, render.color(255,255, 255, 255))
        else
            render.text(pixel, x+offset_scope + 30, y + 30+ay, text5, render.color(255,255, 255, 128))
        end

    if SP then
            render.text(pixel, x+offset_scope + 42, y + 30+ay, text6, render.color(255,255, 255, 255))
        else
            render.text(pixel, x+offset_scope + 42, y + 30+ay, text6, render.color(255,255, 255, 128))
        end
    end

if indicatorsmain:get_int() == 2 then
    
    local alpha2 = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
    local lp = entities.get_entity(engine.get_local_player())
    if not lp then return end
    if not lp:is_alive() then return end
    local local_player = entities.get_entity(engine.get_local_player())
    local ay = 0
    local desync_percentage = Clamp(math.abs(local_player:get_prop("m_flPoseParameter", 11) * 120 - 60.5), 0.5 / 60, 60) / 56
    local w, h = 35, 3
    local screen_width, screen_height = render.get_screen_size( )
    local x = screen_width / 2
    local y = screen_height / 2
    local color1 = render.color(colormain:get_color().r, colormain:get_color().g, colormain:get_color().b, 255)
    local color2 = render.color(colormain:get_color().r - 70, colormain:get_color().g - 90, colormain:get_color().b - 70, 185)

    local text =  "SexWay beta °"
    local textx, texty = render.get_text_size(pixel, text)

    render.text(pixel, x+offset_scope + 5, y + 10, text, render.color(colormain:get_color().r, colormain:get_color().g, colormain:get_color().b, 255))

    render.rect_filled(x + 4 +offset_scope, y + 21, x+offset_scope + w + 5, y + 22 + h + 1, render.color("#000000"))
    render.rect_filled_multicolor(x+offset_scope + 5, y + 22, x+offset_scope + 2 + w * desync_percentage, y + 22 + h, color1, color2, color2, color1)

end
end
--indicators and arrows end

--syncing clantag
local old_time = 0;
local animation = {
    "S",
    "S<",
    "Se",
    "Se3",
    "Sex",
    "SexW3",
    "SexWa",
    "SexWa1",
    "SexWayneg2",
    "SexWaynega<",
    "SexWaynegarx",
    "SexWaynegarx",
    "SexWaynega<",
    "SexWayneg2",
    "SexWa1",
    "SexW3",
    "Sex",
    "Se3<",
    "Se",
    "S<",
    "S",
    
}

--clantag menu element
local function CT()
    if clantagmain:get_bool() then
        local defaultct = Find("misc>various>clan tag")
        local realtime = math.floor((global_vars.realtime) * 1.725)
        if old_time ~= realtime then
            utils.set_clan_tag(animation[realtime % #animation+1]);
        old_time = realtime;
        defaultct:set_bool(false);
        end
    end
end
--clantag end
--callbacks
function on_shutdown()
    utils.set_clan_tag("");
end

function on_create_move()
    UpdateStateandAA()
    StaticFreestand()
    fakeflick()
    InvertDesync()
end

function on_paint()
    MenuElements()
    RB()
    DA()
    WM()
    KB()
    ID()
    CT()
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[[

]]
ffi.cdef [[
    typedef struct{
     void*   handle;
     char    name[260];
     int     load_flags;
     int     server_count;
     int     type;
     int     flags;
     float   mins[3];
     float   maxs[3];
     float   radius;
     char    pad[0x1C];
 } model_t;
 typedef struct {void** this;}aclass;
 typedef void*(__thiscall* get_client_entity_t)(void*, int);
 typedef void(__thiscall* find_or_load_model_fn_t)(void*, const char*);
 typedef const int(__thiscall* get_model_index_fn_t)(void*, const char*);
 typedef const int(__thiscall* add_string_fn_t)(void*, bool, const char*, int, const void*);
 typedef void*(__thiscall* find_table_t)(void*, const char*);
 typedef void(__thiscall* full_update_t)();
 typedef int(__thiscall* get_player_idx_t)();
 typedef void*(__thiscall* get_client_networkable_t)(void*, int);
 typedef void(__thiscall* pre_data_update_t)(void*, int);
 typedef int(__thiscall* get_model_index_t)(void*, const char*);
 typedef const model_t(__thiscall* find_or_load_model_t)(void*, const char*);
 typedef int(__thiscall* add_string_t)(void*, bool, const char*, int, const void*);
 typedef void(__thiscall* set_model_index_t)(void*, int);
 typedef int(__thiscall* precache_model_t)(void*, const char*, bool);
]]
local a = ffi.cast(ffi.typeof("void***"), utils.find_interface("client.dll", "VClientEntityList003")) or
    error("rawientitylist is nil", 2)
local b = ffi.cast("get_client_entity_t", a[0][3]) or error("get_client_entity is nil", 2)
local c = ffi.cast(ffi.typeof("void***"), utils.find_interface("engine.dll", "VModelInfoClient004")) or
    error("model info is nil", 2)
local d = ffi.cast("get_model_index_fn_t", c[0][2]) or error("Getmodelindex is nil", 2)
local e = ffi.cast("find_or_load_model_fn_t", c[0][43]) or error("findmodel is nil", 2)
local f = ffi.cast(ffi.typeof("void***"), utils.find_interface("engine.dll", "VEngineClientStringTable001")) or
    error("clientstring is nil", 2)
local g = ffi.cast("find_table_t", f[0][3]) or error("find table is nil", 2)
function p(pa)
    local a_p = ffi.cast(ffi.typeof("void***"), g(f, "modelprecache"))
    if a_p ~= nil then
        e(c, pa)
        local ac = ffi.cast("add_string_fn_t", a_p[0][8]) or error("ac nil", 2)
        local acs = ac(a_p, false, pa, -1, nil)
        if acs == -1 then print("failed")
            return false
        end
    end
    return true
end

function smi(en, i)
    local rw = b(a, en)
    if rw then
        local gc = ffi.cast(ffi.typeof("void***"), rw)
        local se = ffi.cast("set_model_index_t", gc[0][75])
        if se == nil then
            error("smi is nil")
        end
        se(gc, i)
    end
end

function cm(ent, md)
    if md:len() > 5 then
        if p(md) == false then
            error("invalid model", 2)
        end
        local i = d(c, md)
        if i == -1 then
            return
        end
        smi(ent, i)
    end
end


-------------------------------------Droch4 ModelChanger------------------------------------------

local path = {
    --path
    "models/player/custom_player/legacy/ctm_gsg9.mdl",
    "models/player/custom_player/legacy/ctm_gign.mdl",
    "models/csgo/models/player/custom_player/z-piks.ru/gta_blood.mdl",
    "models/player/custom_player/z-piks.ru/gta_crip.mdl",
    "models/player/custom_player/frnchise9812/ballas1.mdl",
    "models/player/custom_player/kirby/kumlafbi/kumlafbi.mdl",
    "models/player/custom_player/tate_skeet/andrewtate.mdl",
    "models/player/custom_player/kuristaja/putin/putin.mdl",
    "models/player/custom_player/kuristaja/kim_jong_un/kim.mdl",
    "models/player/custom_player/frnchise9812/ballas2.mdl",
    "models/player/custom_player/eminem/gta_sa/swmotr5.mdl",
    "models/player/custom_player/eminem/gta_sa/wuzimu.mdl",
    "models/player/custom_player/eminem/gta_sa/bmybar.mdl",
    "models/player/custom_player/eminem/gta_sa/fam1.mdl",
    "models/player/custom_player/eminem/gta_sa/somyst.mdl",
    "models/player/custom_player/eminem/css/t_arctic.mdl",
    "models/player/custom_player/kuristaja/cso2/goth_schoolgirl/goth.mdl",
    "models/player/custom_player/eminem/gta_sa/vwfypro.mdl",
}

local menu = {}
menu.add = {
    en = gui.add_checkbox("Enabled", "lua>tab a"),
    path = gui.add_combo("Model Changer SexW (error check ds)", "lua>tab a", path),
}

-------------------------------------CrazyTaco ModelChanger------------------------------------------
local function a(a,b)local a=ffi.typeof(a)return function(c,...)local c=ffi.cast("void***",c)return ffi.cast(a,c[0][b])(c,...)end end;ffi.cdef[[

    struct pose_parameters_t
    {
        char pad[8];
        float m_flStart;
        float m_flEnd;
        float m_flState;
    };
]]
local b=utils.find_interface("client.dll","VClientEntityList003")local a=a("void*(__thiscall*)(void*, int)",3)local c={}c.collected_cache={}local d=10576;local e=39264;local f=265;local g="55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15"get_pose_parameters=ffi.cast("struct pose_parameters_t*(__thiscall* )(void*, int)",utils.find_pattern("client.dll",g))local g=gui.get_config_item("Rage>Anti-Aim>Desync>Leg Slide")local h=gui.get_config_item("misc>movement>fake duck")local i=false;local i=false;local i=false;local i=10;local i=2;function SetPose(a,b,e,f)local a=ffi.cast("unsigned int",a)local g=0;if a==g then return false end;local a=ffi.cast("void**",a+d)[0]if not a or a==g then return false end;local a=get_pose_parameters(a,b)if not a or a==g then return false end;if c.collected_cache[b]==nil then c.collected_cache[b]={}c.collected_cache[b].m_flStart=a.m_flStart;c.collected_cache[b].m_flEnd=a.m_flEnd;c.collected_cache[b].m_flState=a.m_flState;c.collected_cache[b].is_applied=false;return true end;if e~=nil and not c.collected_cache[b].is_applied then a.m_flStart=e;a.m_flEnd=f;a.m_flState=(a.m_flStart+a.m_flEnd)/2;c.collected_cache[b].is_applied=true;return true end;if c.collected_cache[b].is_applied then a.m_flStart=c.collected_cache[b].m_flStart;a.m_flEnd=c.collected_cache[b].m_flEnd;a.m_flState=c.collected_cache[b].m_flState;c.collected_cache[b].is_applied=false;return true end;return false end;local d,i,j,k,l,m=gui.add_multi_combo("modern breaker","lua>tab a",{"air static","air break","legs jitter","legs static","lower body yaw","fake duck breaker"})function on_create_move(c)local c=engine.get_local_player()local a=a(b,c)local b=0;if not a or a==b then return end;local c=ffi.cast("unsigned int",a)if not c or c==b then return end;local e=e;local c=ffi.cast("void**",c+e)[0]if not c or c==b then return end;c=ffi.cast("unsigned int",c)if not c or c==0 then return end;local c=ffi.cast("bool*",c+f)[0]if not f or f==b then return end;local b=bit.band(entities.get_entity(engine.get_local_player()):get_prop("m_fFlags"),bit.lshift(2,0))~=0;if i:get_bool()then if utils.random_int(0,1)==0 then SetPose(a,6,0,1)else SetPose(a,6,0.1,0)end elseif d:get_bool()then SetPose(a,6,0.7,1)else SetPose(a,6,0.1,0)end;if j:get_bool()then g:set_int(2)if utils.random_int(0,1)>0 then SetPose(a,0,0,20)else SetPose(a,0,14,10)end elseif k:get_bool()then SetPose(a,0,0,20)end;if l:get_bool()then SetPose(a,10,0,0)end;if m:get_bool()then if h:get_bool()then if utils.random_int(0,5)==0 then SetPose(a,16,0,0)else SetPose(a,16,10,0)end end end end;function on_setup_move(d)local d=engine.get_local_player()local a=a(b,d)local b=0;if not a or a==b then return end;local b=c.collected_cache;for b,c in pairs(b)do SetPose(a,b)end end

function on_frame_stage_notify(stage, pre_original)
    if stage == csgo.frame_render_start then
        local player = entities.get_entity(engine.get_local_player())
        if player == nil then return end
        if player:is_alive() then
            if menu.add.en:get_bool() then
                cm(player:get_index(), path[menu.add.path:get_int() + 1])
            end
        end
    end
end

local enabled = gui.add_checkbox ( "auto Defensive AA", "lua>tab a" )

local dt = gui.get_config_item ( "rage>aimbot>aimbot>Double Tap" )
local hs = gui.get_config_item ( "rage>aimbot>aimbot>Hide shot" )

local fl_frozen = bit.lshift ( 1, 6 )

local in_attack = bit.lshift ( 1, 0 )
local in_attack2 = bit.lshift ( 1, 11 )


local checker = 0
local defensive = false

function on_create_move ( cmd )
    local me = entities.get_entity ( engine.get_local_player ( ) )
    if not me or not me:is_valid ( ) then
        return
    end

    local tickbase = me:get_prop ( "m_nTickBase" )

    defensive = math.abs ( tickbase - checker ) >= 3
    checker = math.max ( tickbase, checker or 0 )
end

function on_player_spawn ( event )
    if engine.get_player_for_user_id ( event:get_int ( 'userid' ) ) == engine.get_local_player ( ) then
        checker = 0
    end
end

function on_run_command ( cmd )
    if not enabled:get_bool ( ) or not dt:get_bool ( ) and not hs:get_bool ( ) then
        return
    end

    local buttons = cmd:get_buttons ( )
    if bit.band ( buttons, in_attack ) == in_attack or bit.band ( buttons, in_attack2 ) == in_attack2 then
        return
    end

    local me = entities.get_entity ( engine.get_local_player ( ) )
    if not me or not me:is_valid ( ) then
        return
    end

    local flags = me:get_prop ( 'm_fFlags' )
    if bit.band ( flags, fl_frozen ) == fl_frozen then
        return
    end

    if info.fatality.lag_ticks > 1 then
        return
    end

    if defensive then
        cmd:set_view_angles ( utils.random_int ( -359, 359 ), utils.random_int ( -88, 88 ), 0 )
    elseif info.fatality.can_fastfire == false then
        cmd:set_view_angles ( utils.random_int ( -359, 359 ), utils.random_int ( -88, 88 ), 0 )
    end
end

local safe = {
    _VERSION    = 1.1,
    _URL        = 'https://github.com/Bilwin/gmod-scripts/blob/main/safe.lua',
    _LICENSE    = 'https://github.com/Bilwin/gmod-scripts/blob/main/LICENSE'
}
function safe:html(str)
    return str:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

function safe:steam_id(str)
    return str:gsub('[^%w:_]', '') or ''
end

function safe:explode_quotes(str)
	str = ' ' .. str .. ' '
	local res = {}
	local ind = 1

	while true do
		local sInd, start = str:find('[^%s]', ind)
		if not sInd then break end
		ind = sInd + 1
		local quoted = str:sub(sInd, sInd):match('["\']') and true or false
		local fInd, finish = str:find(quoted and '["\'][%s]', ind)
		if not fInd then break end
		ind = fInd + 1
		local str = str:sub(quoted and sInd + 1 or sInd, fInd - 1)
		res[#res + 1] = str
	end

	return res
end
