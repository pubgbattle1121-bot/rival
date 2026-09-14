--//=========================================================
--// 크랙본 by R0W | Full build + config persistence
--// F1 UI, F2 purge. Drag via top bar. All toggles OFF on fresh install.
--//=========================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local LP = Players.LocalPlayer

if cleardrawcache then pcall(cleardrawcache) end
for _, g in ipairs(CoreGui:GetChildren()) do
    if g.Name == "crackbonUI" or g.Name == "SerotoninUI" then pcall(function() g:Destroy() end) end
end

--// SAVE SYSTEM
local Save = {
    path = "crackbon_cfg.json",
    entries = {},
    canSave = (typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"),
}

local function registerSave(key, getter, setter)
    Save.entries[key] = { get = getter, set = setter }
end

local function saveConfig()
    if not Save.canSave then return end
    local data = {}
    for k, e in pairs(Save.entries) do
        local ok, v = pcall(e.get)
        if ok then data[k] = v end
    end
    pcall(function()
        writefile(Save.path, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if not Save.canSave then return false end
    local ok1 = pcall(function() return isfile(Save.path) end)
    if not ok1 then return false end
    local exists = pcall(function() return isfile(Save.path) end) and isfile(Save.path)
    if not exists then return false end

    local content
    if not pcall(function() content = readfile(Save.path) end) then return false end
    if not content or content == "" then return false end

    local data
    if not pcall(function() data = HttpService:JSONDecode(content) end) then return false end
    if type(data) ~= "table" then return false end

    for k, v in pairs(data) do
        local e = Save.entries[k]
        if e then pcall(e.set, v) end
    end
    return true
end

local function resetConfig()
    if Save.canSave then
        pcall(function() if isfile(Save.path) then delfile(Save.path) end end)
    end
end

--// REGISTRY
local Registry = { all = {} }
local function reg(d) if d then table.insert(Registry.all, d) end; return d end
local function unreg(d)
    for i, x in ipairs(Registry.all) do if x == d then table.remove(Registry.all, i); break end end
end
local function removeDrawing(d)
    if not d then return end
    pcall(function() d.Visible = false end); pcall(function() d:Remove() end); unreg(d)
end
local function purgeAll()
    for _, d in ipairs(Registry.all) do
        pcall(function() d.Visible = false end); pcall(function() d:Remove() end)
    end
    Registry.all = {}
end
local function hideAll()
    for _, d in ipairs(Registry.all) do pcall(function() d.Visible = false end) end
end

--// BIND HELPERS
local function inputToBind(input)
    if not input then return nil end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local kc = input.KeyCode
        if kc and kc ~= Enum.KeyCode.Unknown then
            return { kind="key", value=kc, name=kc.Name }
        end
        return nil
    end
    local n = input.UserInputType and input.UserInputType.Name or ""
    if n == "MouseButton1" or n == "MouseButton2" or n == "MouseButton3"
        or n == "MouseButton4" or n == "MouseButton5" then
        return { kind="mouse", value=input.UserInputType, name=n }
    end
    return nil
end

local function inputMatchesBind(input, bind)
    if not bind or not input then return false end
    if bind.kind == "key" then
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind.value
    end
    if bind.kind == "mouse" then
        return input.UserInputType == bind.value
    end
    return false
end

--// CONFIG
local DEFAULT_BIND = { kind="key", value=Enum.KeyCode.LeftShift, name="LeftShift" }

local Config = {
    Skybox = "Default",
    Visuals = {
        Enabled=false, TeamCheck=false, VisCheck=false, MaxDistance=1000,
        Box=false, BoxFilled=false, BoxPadding=0.5,
        Name=false, Distance=false, Health=false, HeadDot=false,
        Tracer=false, Skeleton=false,
        Chams=false, ChamsFill=Color3.fromRGB(0,200,200), ChamsOutline=Color3.fromRGB(255,255,255),
        ChamsThroughWalls=true, ChamsTransparency=0.6,
        Color=Color3.fromRGB(0,220,220), TeamColor=false,
    },
    Aimbot = {
        Enabled=false,
        TeamCheck=false, VisCheck=false, WallCheck=false,
        TargetPart="Head",
        FOV=150, FOVColor=Color3.fromRGB(0,220,220), DrawFOV=false,
        MaxDistance=1000, Smoothness=0.2, Prediction=0.15,
        Snapline=false,
        ScriptableCamera=false,
        Offset=Vector3.new(0,0,0),
    },
    Triggerbot = {
        Enabled=false,
        UseKey=false,
        Bind=DEFAULT_BIND,
        Mode="FOV",
        FOV=150, FOVColor=Color3.fromRGB(255,90,90), DrawFOV=false,
        TargetPart="Head",
        KeyFOV=150,
        KeyAimSmoothness=0.35,
        KeyPrediction=0.15,
        TeamCheck=false, VisCheck=false,
        Delay=40, ClickDuration=30, Hitchance=100,
        MaxDistance=500,
        Burst=false, BurstCount=3,
    },
}

local function readCfg(path)
    local cur = Config
    for p in path:gmatch("[^.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[p]
    end
    return cur
end
local function writeCfg(path, v)
    local parts = {}
    for p in path:gmatch("[^.]+") do parts[#parts+1] = p end
    local cur = Config
    for i = 1, #parts - 1 do cur = cur[parts[i]] end
    cur[parts[#parts]] = v
end

--// TEAM
local function sameTeam(a, b)
    if not a or not b then return false end
    if a == b then return true end
    local ta, tb = a.Team, b.Team
    if ta and tb and ta == tb then return true end
    local ca, cb = a.TeamColor, b.TeamColor
    if ca and cb and ca == cb then return true end
    return false
end
local function teamColor(player)
    if player.Team then return player.TeamColor.Color end
    if player.TeamColor then return player.TeamColor.Color end
    return Config.Visuals.Color
end

--// SKY (soft atmosphere tint)
local SkyState = { savedSky=nil, savedAtm=nil, savedProps={}, appliedSky=nil, appliedAtm=nil, savedOnce=false }

local function snapshotLighting()
    SkyState.savedProps = {
        FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, FogColor=Lighting.FogColor,
        Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
        Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
        GlobalShadows=Lighting.GlobalShadows, ExposureCompensation=Lighting.ExposureCompensation,
    }
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then pcall(function() SkyState.savedSky = sky:Clone() end) end
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then pcall(function() SkyState.savedAtm = atm:Clone() end) end
    SkyState.savedOnce = true
end

local function killDynamic()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") then pcall(function() v:Destroy() end) end
    end
    SkyState.appliedSky = nil; SkyState.appliedAtm = nil
end

local function restoreOriginal()
    killDynamic()
    if SkyState.savedSky then local c = SkyState.savedSky:Clone(); c.Parent = Lighting end
    if SkyState.savedAtm then local c = SkyState.savedAtm:Clone(); c.Parent = Lighting end
    local p = SkyState.savedProps
    if p then
        Lighting.FogEnd=p.FogEnd; Lighting.FogStart=p.FogStart; Lighting.FogColor=p.FogColor
        Lighting.Ambient=p.Ambient; Lighting.OutdoorAmbient=p.OutdoorAmbient
        Lighting.Brightness=p.Brightness; Lighting.ClockTime=p.ClockTime
        Lighting.GlobalShadows=p.GlobalShadows; Lighting.ExposureCompensation=p.ExposureCompensation
    end
end

local function applyAtmosphereTint(color, opts)
    opts = opts or {}
    killDynamic()
    local atm = Instance.new("Atmosphere")
    atm.Name="crackbonAtm"; atm.Color=color
    atm.Decay = opts.decay or Color3.fromRGB(80,90,105)
    atm.Density = opts.density or 0.22
    atm.Glare = opts.glare or 0
    atm.Haze = opts.haze or 1.2
    atm.Offset = 0
    atm.Parent = Lighting
    SkyState.appliedAtm = atm

    Lighting.FogStart=0; Lighting.FogEnd=1e9; Lighting.FogColor=Color3.fromRGB(180,180,180)
    Lighting.Ambient = opts.ambient or Color3.fromRGB(110,110,110)
    Lighting.OutdoorAmbient = opts.outdoor or Color3.fromRGB(140,140,140)
    Lighting.Brightness = opts.brightness or 2
    if opts.clockTime then Lighting.ClockTime = opts.clockTime end
    Lighting.GlobalShadows = true
end

local SPACE_SKY = {
    Bk="rbxassetid://159454299", Dn="rbxassetid://159454296", Ft="rbxassetid://159454293",
    Lf="rbxassetid://159454286", Rt="rbxassetid://159454300", Up="rbxassetid://159454288",
}

local function applyRealSky(images)
    killDynamic()
    local sky = Instance.new("Sky")
    sky.Name="crackbonSky"
    sky.SkyboxBk=images.Bk; sky.SkyboxDn=images.Dn; sky.SkyboxFt=images.Ft
    sky.SkyboxLf=images.Lf; sky.SkyboxRt=images.Rt; sky.SkyboxUp=images.Up
    sky.SunAngularSize=0; sky.MoonAngularSize=0
    sky.Parent = Lighting
    SkyState.appliedSky = sky
    Lighting.FogStart=0; Lighting.FogEnd=1e9; Lighting.FogColor=Color3.fromRGB(180,180,180)
    Lighting.Ambient=Color3.fromRGB(20,20,20); Lighting.OutdoorAmbient=Color3.fromRGB(90,90,90)
    Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.GlobalShadows=true
end

local function applySkybox(name)
    if not SkyState.savedOnce then snapshotLighting() end
    if name == "Default" then restoreOriginal()
    elseif name == "Space" then applyRealSky(SPACE_SKY)
    elseif name == "Red" then
        applyAtmosphereTint(Color3.fromRGB(230,150,150), {density=0.20,haze=1.2,glare=0.15,ambient=Color3.fromRGB(120,100,100),outdoor=Color3.fromRGB(180,140,140)})
    elseif name == "Orange" then
        applyAtmosphereTint(Color3.fromRGB(240,190,140), {density=0.20,haze=1.2,glare=0.20,ambient=Color3.fromRGB(130,110,90),outdoor=Color3.fromRGB(200,170,140)})
    elseif name == "Yellow" then
        applyAtmosphereTint(Color3.fromRGB(240,230,170), {density=0.20,haze=1.2,glare=0.25,ambient=Color3.fromRGB(140,135,105),outdoor=Color3.fromRGB(210,200,170)})
    elseif name == "Green" then
        applyAtmosphereTint(Color3.fromRGB(160,220,175), {density=0.20,haze=1.2,glare=0.15,ambient=Color3.fromRGB(105,130,110),outdoor=Color3.fromRGB(160,200,170)})
    elseif name == "Blue" then
        applyAtmosphereTint(Color3.fromRGB(160,190,235), {density=0.20,haze=1.2,glare=0.15,ambient=Color3.fromRGB(105,120,150),outdoor=Color3.fromRGB(160,185,220)})
    elseif name == "Purple" then
        applyAtmosphereTint(Color3.fromRGB(205,175,235), {density=0.20,haze=1.2,glare=0.15,ambient=Color3.fromRGB(125,110,150),outdoor=Color3.fromRGB(185,165,215)})
    elseif name == "Pink" then
        applyAtmosphereTint(Color3.fromRGB(240,190,215), {density=0.20,haze=1.2,glare=0.15,ambient=Color3.fromRGB(140,115,125),outdoor=Color3.fromRGB(210,180,195)})
    elseif name == "Night" then
        applyAtmosphereTint(Color3.fromRGB(60,75,120), {density=0.25,haze=0.8,glare=0,clockTime=0,ambient=Color3.fromRGB(40,50,80),outdoor=Color3.fromRGB(55,70,100),brightness=1.2})
    elseif name == "Sunset" then
        applyAtmosphereTint(Color3.fromRGB(240,175,140), {density=0.22,haze=1.5,glare=0.3,clockTime=17.5,ambient=Color3.fromRGB(120,95,85),outdoor=Color3.fromRGB(200,165,140)})
    elseif name == "Dawn" then
        applyAtmosphereTint(Color3.fromRGB(235,190,210), {density=0.22,haze=1.3,glare=0.25,clockTime=6,ambient=Color3.fromRGB(120,105,115),outdoor=Color3.fromRGB(200,180,190)})
    end
end

snapshotLighting()

--// UI
local parent = (gethui and gethui()) or CoreGui
local Colors = {
    BG=Color3.fromRGB(28,28,32), Panel=Color3.fromRGB(36,36,42), Header=Color3.fromRGB(22,22,26),
    Accent=Color3.fromRGB(0,200,200), Text=Color3.fromRGB(220,220,225), SubText=Color3.fromRGB(150,150,160),
    Line=Color3.fromRGB(50,50,58), Off=Color3.fromRGB(70,70,78), On=Color3.fromRGB(0,200,200),
    Danger=Color3.fromRGB(220,80,80),
}
local function new(c, p) local o = Instance.new(c); for k,v in pairs(p or {}) do o[k]=v end; return o end
local function corner(r) return new("UICorner", {CornerRadius=UDim.new(0, r or 4)}) end
local function stroke(c, t) return new("UIStroke", {Color=c or Colors.Line, Thickness=t or 1}) end

local ScreenGui = new("ScreenGui", {Name="crackbonUI", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=parent})
local Main = new("Frame", {Size=UDim2.fromOffset(720,540), Position=UDim2.new(0.5,-360,0.5,-270), BackgroundColor3=Colors.BG, BorderSizePixel=0, Parent=ScreenGui})
corner(6); stroke(Colors.Line,1)
Main.Active=false; Main.Draggable=false

local TopBar = new("Frame", {Size=UDim2.new(1,0,0,28), BackgroundColor3=Colors.Header, BorderSizePixel=0, Parent=Main})
corner(6)
new("TextLabel", {Size=UDim2.new(0,300,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamSemibold, Text="크랙본 by R0W", TextColor3=Colors.Accent, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, Parent=TopBar})

do
    local dragging, dragStart, startPos = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local TabBar = new("Frame", {Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,28), BackgroundColor3=Colors.Header, BorderSizePixel=0, Parent=Main})
local Content = new("Frame", {Size=UDim2.new(1,0,1,-54), Position=UDim2.new(0,0,0,54), BackgroundTransparency=1, Parent=Main})

local Tabs = {}
local TAB_W = 110
local function makeTab(name)
    local btn = new("TextButton", {Size=UDim2.new(0,TAB_W,1,0), BackgroundColor3=Colors.Header, BorderSizePixel=0, Font=Enum.Font.GothamMedium, Text=name, TextColor3=Colors.SubText, TextSize=12, Parent=TabBar})
    local page = new("ScrollingFrame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=3, ScrollBarImageColor3=Colors.Accent, Visible=false, Parent=Content})
    Tabs[name] = {button=btn, page=page}
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.button.TextColor3=Colors.SubText; t.page.Visible=false end
        btn.TextColor3=Colors.Accent; page.Visible=true
    end)
    return Tabs[name]
end
for i, name in ipairs({"Aimbot","Triggerbot","Visuals","Settings"}) do
    local t = makeTab(name)
    t.button.Position = UDim2.new(0, (i-1)*TAB_W, 0, 0)
    if name=="Visuals" then t.button.TextColor3=Colors.Accent; t.page.Visible=true end
end

local function makeColumn(tab, side)
    local col = new("Frame", {Size=UDim2.new(0.5,-12,0,0), Position=side=="right" and UDim2.new(0.5,6,0,0) or UDim2.new(0,6,0,0), BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.Y, Parent=tab.page})
    new("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder, Parent=col})
    return col
end
local function makeSection(parentCol, title)
    local sec = new("Frame", {Size=UDim2.new(1,0,0,22), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Parent=parentCol})
    corner(3)
    new("TextLabel", {Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Font=Enum.Font.GothamSemibold, Text=title, TextColor3=Colors.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=sec})
    return sec
end
local function makeRow(parentCol) return new("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Parent=parentCol}) end

local function makeToggle(parentCol, label, cfgPath, default, callback)
    local row = makeRow(parentCol)
    new("TextLabel", {Size=UDim2.new(1,-30,1,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=label, TextColor3=Colors.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local box = new("TextButton", {Size=UDim2.new(0,14,0,14), Position=UDim2.new(1,-16,0.5,-7), BackgroundColor3=default and Colors.On or Colors.Off, BorderSizePixel=0, Text="", Parent=row})
    corner(2)
    local function apply(v)
        box.BackgroundColor3 = v and Colors.On or Colors.Off
        if callback then callback(v) end
    end
    apply(default)

    if cfgPath then
        registerSave(cfgPath, function() return readCfg(cfgPath) end, function(v)
            writeCfg(cfgPath, v); apply(v)
        end)
    end

    box.MouseButton1Click:Connect(function()
        local state = box.BackgroundColor3 ~= Colors.On
        apply(state)
        if cfgPath then saveConfig() end
    end)
end

local function makeSlider(parentCol, label, cfgPath, min, max, default, decimals, callback)
    local row = new("Frame", {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Parent=parentCol})
    new("TextLabel", {Size=UDim2.new(1,-60,0,14), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=label, TextColor3=Colors.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local val = new("TextLabel", {Size=UDim2.new(0,60,0,14), Position=UDim2.new(1,-60,0,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=tostring(default), TextColor3=Colors.Accent, TextSize=11, TextXAlignment=Enum.TextXAlignment.Right, Parent=row})
    local bar = new("Frame", {Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,20), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Parent=row})
    corner(2)
    local fill = new("Frame", {Size=UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3=Colors.Accent, BorderSizePixel=0, Parent=bar})
    corner(2)

    local function setVal(v)
        local rel = (v - min) / (max - min)
        fill.Size = UDim2.new(math.clamp(rel,0,1),0,1,0)
        val.Text = tostring(v)
        if callback then callback(v) end
    end

    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = tonumber(string.format("%."..(decimals or 0).."f", min + (max-min)*rel))
        setVal(v)
        if cfgPath then saveConfig() end
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; update(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    if cfgPath then
        registerSave(cfgPath, function() return readCfg(cfgPath) end, function(v) writeCfg(cfgPath, v); setVal(v) end)
    end
    setVal(default)
end

local function makeDropdown(parentCol, label, cfgPath, options, default, callback)
    local row = new("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, ClipsDescendants=false, Parent=parentCol})
    new("TextLabel", {Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=label, TextColor3=Colors.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local btn = new("TextButton", {Size=UDim2.new(0.5,-4,1,0), Position=UDim2.new(0.5,4,0,0), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Font=Enum.Font.Gotham, Text=default, TextColor3=Colors.Text, TextSize=11, Parent=row})
    corner(2)
    local list = new("Frame", {Size=UDim2.new(0.5,-4,0,#options*18), Position=UDim2.new(0.5,4,1,2), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Visible=false, ZIndex=20, Parent=row})
    corner(2)
    for i, opt in ipairs(options) do
        local o = new("TextButton", {Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,(i-1)*18), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=opt, TextColor3=Colors.Text, TextSize=11, ZIndex=21, Parent=list})
        o.MouseButton1Click:Connect(function()
            btn.Text=opt; list.Visible=false
            if callback then callback(opt) end
            if cfgPath then saveConfig() end
        end)
    end
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)

    local function setVal(v)
        btn.Text = v
        if callback then callback(v) end
    end

    if cfgPath then
        registerSave(cfgPath, function() return readCfg(cfgPath) end, function(v) writeCfg(cfgPath, v); setVal(v) end)
    end
    if callback then callback(default) end
end

local function makeKeybind(parentCol, label, cfgPath, defaultBind, callback)
    local row = new("Frame", {Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Parent=parentCol})
    new("TextLabel", {Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text=label, TextColor3=Colors.Text, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
    local btn = new("TextButton", {Size=UDim2.new(0.5,-4,1,0), Position=UDim2.new(0.5,4,0,0), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Font=Enum.Font.Gotham, Text=defaultBind and defaultBind.name or "None", TextColor3=Colors.Text, TextSize=11, Parent=row})
    corner(2)

    local listening = false
    local currentBind = defaultBind
    local listenConn = nil

    local function stopListening()
        listening = false
        btn.Text = currentBind and currentBind.name or "None"
        btn.BackgroundColor3 = Colors.Panel
        btn.TextColor3 = Colors.Text
        if listenConn then listenConn:Disconnect(); listenConn = nil end
    end

    local function startListening()
        listening = true
        btn.Text = "Press a key..."
        btn.BackgroundColor3 = Colors.Accent
        btn.TextColor3 = Colors.BG
        listenConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
                stopListening(); return
            end
            local b = inputToBind(input)
            if b then
                currentBind = b
                btn.Text = b.name
                if callback then callback(b) end
                if cfgPath then saveConfig() end
                stopListening()
            end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if listening then stopListening() else startListening() end
    end)

    if cfgPath then
        registerSave(cfgPath,
            function()
                local b = readCfg(cfgPath)
                if type(b) == "table" and b.kind then return b end
                return nil
            end,
            function(b)
                if type(b) ~= "table" or not b.kind then return end
                local v
                if b.kind == "key" then
                    local ok = pcall(function() v = Enum.KeyCode[b.name] end)
                    if not ok or not v then return end
                elseif b.kind == "mouse" then
                    local ok = pcall(function() v = Enum.UserInputType[b.name] end)
                    if not ok or not v then return end
                else return end
                currentBind = { kind=b.kind, value=v, name=b.name }
                writeCfg(cfgPath, currentBind)
                btn.Text = currentBind.name
                if callback then callback(currentBind) end
            end
        )
    end

    if callback and defaultBind then callback(defaultBind) end
end

--// AIMBOT TAB
do
    local tab = Tabs.Aimbot
    local L = makeColumn(tab, "left")
    local R = makeColumn(tab, "right")
    makeSection(L, "Aimbot")
    makeToggle(L, "Enabled", "Aimbot.Enabled", Config.Aimbot.Enabled, function(v) Config.Aimbot.Enabled = v end)
    makeDropdown(L, "Target Part", "Aimbot.TargetPart", {"Head","UpperTorso","LowerTorso","Nearest"}, Config.Aimbot.TargetPart, function(v) Config.Aimbot.TargetPart = v end)
    makeSlider(L, "Smoothness", "Aimbot.Smoothness", 0.01, 1, Config.Aimbot.Smoothness, 2, function(v) Config.Aimbot.Smoothness = v end)
    makeSlider(L, "Prediction", "Aimbot.Prediction", 0, 1, Config.Aimbot.Prediction, 2, function(v) Config.Aimbot.Prediction = v end)
    makeSlider(L, "Max Distance", "Aimbot.MaxDistance", 0, 3000, Config.Aimbot.MaxDistance, 0, function(v) Config.Aimbot.MaxDistance = v end)
    makeToggle(L, "Scriptable Cam", "Aimbot.ScriptableCamera", Config.Aimbot.ScriptableCamera, function(v) Config.Aimbot.ScriptableCamera = v end)
    makeSection(R, "Aimbot FOV")
    makeSlider(R, "FOV", "Aimbot.FOV", 0, 500, Config.Aimbot.FOV, 0, function(v) Config.Aimbot.FOV = v end)
    makeToggle(R, "Draw FOV", "Aimbot.DrawFOV", Config.Aimbot.DrawFOV, function(v) Config.Aimbot.DrawFOV = v end)
    makeToggle(R, "Snapline", "Aimbot.Snapline", Config.Aimbot.Snapline, function(v) Config.Aimbot.Snapline = v end)
    makeSection(R, "Aimbot Checks")
    makeToggle(R, "Team Check", "Aimbot.TeamCheck", Config.Aimbot.TeamCheck, function(v) Config.Aimbot.TeamCheck = v end)
    makeToggle(R, "Visibility Check", "Aimbot.VisCheck", Config.Aimbot.VisCheck, function(v) Config.Aimbot.VisCheck = v end)
    makeToggle(R, "Wall Check", "Aimbot.WallCheck", Config.Aimbot.WallCheck, function(v) Config.Aimbot.WallCheck = v end)
end

--// TRIGGERBOT TAB
do
    local tab = Tabs.Triggerbot
    local L = makeColumn(tab, "left")
    local R = makeColumn(tab, "right")
    makeSection(L, "Triggerbot")
    makeToggle(L, "Enabled", "Triggerbot.Enabled", Config.Triggerbot.Enabled, function(v) Config.Triggerbot.Enabled = v end)
    makeToggle(L, "Use Key Hold", "Triggerbot.UseKey", Config.Triggerbot.UseKey, function(v) Config.Triggerbot.UseKey = v end)
    makeKeybind(L, "Keybind", "Triggerbot.Bind", Config.Triggerbot.Bind, function(b) Config.Triggerbot.Bind = b end)
    makeSlider(L, "Key FOV", "Triggerbot.KeyFOV", 0, 500, Config.Triggerbot.KeyFOV, 0, function(v) Config.Triggerbot.KeyFOV = v end)
    makeSlider(L, "Key Smoothness", "Triggerbot.KeyAimSmoothness", 0.05, 1, Config.Triggerbot.KeyAimSmoothness, 2, function(v) Config.Triggerbot.KeyAimSmoothness = v end)
    makeSlider(L, "Key Prediction", "Triggerbot.KeyPrediction", 0, 1, Config.Triggerbot.KeyPrediction, 2, function(v) Config.Triggerbot.KeyPrediction = v end)
    makeSection(L, "Auto Mode (Use Key OFF)")
    makeDropdown(L, "Mode", "Triggerbot.Mode", {"FOV","Crosshair"}, Config.Triggerbot.Mode, function(v) Config.Triggerbot.Mode = v end)
    makeDropdown(L, "Target Part", "Triggerbot.TargetPart", {"Head","UpperTorso","LowerTorso","Nearest"}, Config.Triggerbot.TargetPart, function(v) Config.Triggerbot.TargetPart = v end)
    makeSlider(L, "FOV", "Triggerbot.FOV", 0, 500, Config.Triggerbot.FOV, 0, function(v) Config.Triggerbot.FOV = v end)
    makeToggle(L, "Draw FOV", "Triggerbot.DrawFOV", Config.Triggerbot.DrawFOV, function(v) Config.Triggerbot.DrawFOV = v end)
    makeSection(R, "Shared")
    makeSlider(R, "Delay (ms)", "Triggerbot.Delay", 0, 500, Config.Triggerbot.Delay, 0, function(v) Config.Triggerbot.Delay = v end)
    makeSlider(R, "Click Duration (ms)", "Triggerbot.ClickDuration", 0, 300, Config.Triggerbot.ClickDuration, 0, function(v) Config.Triggerbot.ClickDuration = v end)
    makeSlider(R, "Hitchance", "Triggerbot.Hitchance", 0, 100, Config.Triggerbot.Hitchance, 0, function(v) Config.Triggerbot.Hitchance = v end)
    makeSlider(R, "Max Distance", "Triggerbot.MaxDistance", 0, 2000, Config.Triggerbot.MaxDistance, 0, function(v) Config.Triggerbot.MaxDistance = v end)
    makeToggle(R, "Burst Mode", "Triggerbot.Burst", Config.Triggerbot.Burst, function(v) Config.Triggerbot.Burst = v end)
    makeSlider(R, "Burst Count", "Triggerbot.BurstCount", 1, 10, Config.Triggerbot.BurstCount, 0, function(v) Config.Triggerbot.BurstCount = v end)
    makeSection(R, "Checks")
    makeToggle(R, "Team Check", "Triggerbot.TeamCheck", Config.Triggerbot.TeamCheck, function(v) Config.Triggerbot.TeamCheck = v end)
    makeToggle(R, "Visibility Check", "Triggerbot.VisCheck", Config.Triggerbot.VisCheck, function(v) Config.Triggerbot.VisCheck = v end)
end

--// VISUALS TAB
do
    local tab = Tabs.Visuals
    local L = makeColumn(tab, "left")
    local R = makeColumn(tab, "right")
    makeSection(L, "Visuals")
    makeToggle(L, "Enabled", "Visuals.Enabled", Config.Visuals.Enabled, function(v) Config.Visuals.Enabled = v end)
    makeToggle(L, "Team Check", "Visuals.TeamCheck", Config.Visuals.TeamCheck, function(v) Config.Visuals.TeamCheck = v end)
    makeToggle(L, "Visibility Check", "Visuals.VisCheck", Config.Visuals.VisCheck, function(v) Config.Visuals.VisCheck = v end)
    makeSlider(L, "Max Distance", "Visuals.MaxDistance", 0, 5000, Config.Visuals.MaxDistance, 0, function(v) Config.Visuals.MaxDistance = v end)
    makeSection(L, "Box")
    makeToggle(L, "Box", "Visuals.Box", Config.Visuals.Box, function(v) Config.Visuals.Box = v end)
    makeToggle(L, "Box Filled", "Visuals.BoxFilled", Config.Visuals.BoxFilled, function(v) Config.Visuals.BoxFilled = v end)
    makeSlider(L, "Box Padding", "Visuals.BoxPadding", 0, 2, Config.Visuals.BoxPadding, 2, function(v) Config.Visuals.BoxPadding = v end)
    makeSection(L, "Chams")
    makeToggle(L, "Chams", "Visuals.Chams", Config.Visuals.Chams, function(v) Config.Visuals.Chams = v end)
    makeToggle(L, "Through Walls", "Visuals.ChamsThroughWalls", Config.Visuals.ChamsThroughWalls, function(v) Config.Visuals.ChamsThroughWalls = v end)
    makeSlider(L, "Chams Transparency", "Visuals.ChamsTransparency", 0, 1, Config.Visuals.ChamsTransparency, 2, function(v) Config.Visuals.ChamsTransparency = v end)
    makeSection(R, "Info")
    makeToggle(R, "Name", "Visuals.Name", Config.Visuals.Name, function(v) Config.Visuals.Name = v end)
    makeToggle(R, "Distance", "Visuals.Distance", Config.Visuals.Distance, function(v) Config.Visuals.Distance = v end)
    makeToggle(R, "Health", "Visuals.Health", Config.Visuals.Health, function(v) Config.Visuals.Health = v end)
    makeToggle(R, "Head Dot", "Visuals.HeadDot", Config.Visuals.HeadDot, function(v) Config.Visuals.HeadDot = v end)
    makeToggle(R, "Tracer", "Visuals.Tracer", Config.Visuals.Tracer, function(v) Config.Visuals.Tracer = v end)
    makeToggle(R, "Skeleton", "Visuals.Skeleton", Config.Visuals.Skeleton, function(v) Config.Visuals.Skeleton = v end)
    makeToggle(R, "Team Color", "Visuals.TeamColor", Config.Visuals.TeamColor, function(v) Config.Visuals.TeamColor = v end)
end

--// SETTINGS TAB
do
    local tab = Tabs.Settings
    local L = makeColumn(tab, "left")
    local R = makeColumn(tab, "right")

    makeSection(L, "하늘 색")
    makeDropdown(L, "Sky Preset", "Skybox",
        {"Default","Space","Red","Orange","Yellow","Green","Blue","Purple","Pink","Night","Sunset","Dawn"},
        Config.Skybox,
        function(v) Config.Skybox = v; applySkybox(v) end
    )

    makeSection(L, "조명")
    makeToggle(L, "Fullbright", nil, false, function(v)
        if v then
            Lighting.Brightness = 5
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        else
            restoreOriginal()
        end
    end)

    makeSection(R, "설정 저장")
    do
        local row = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=R})
        local saveBtn = new("TextButton", {Size=UDim2.new(0.5,-3,1,0), BackgroundColor3=Colors.Accent, BorderSizePixel=0, Font=Enum.Font.GothamSemibold, Text="Save", TextColor3=Colors.BG, TextSize=11, Parent=row})
        corner(3)
        local loadBtn = new("TextButton", {Size=UDim2.new(0.5,-3,1,0), Position=UDim2.new(0.5,3,0,0), BackgroundColor3=Colors.Panel, BorderSizePixel=0, Font=Enum.Font.GothamSemibold, Text="Load", TextColor3=Colors.Text, TextSize=11, Parent=row})
        corner(3)
        saveBtn.MouseButton1Click:Connect(function()
            saveConfig()
            saveBtn.Text = "Saved!"
            task.delay(1, function() saveBtn.Text = "Save" end)
        end)
        loadBtn.MouseButton1Click:Connect(function()
            loadConfig()
            loadBtn.Text = "Loaded!"
            task.delay(1, function() loadBtn.Text = "Load" end)
        end)
    end

    do
        local row = new("Frame", {Size=UDim2.new(1,0,0,26), BackgroundTransparency=1, Parent=R})
        local resetBtn = new("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundColor3=Colors.Danger, BorderSizePixel=0, Font=Enum.Font.GothamSemibold, Text="Reset Config (delete save file)", TextColor3=Color3.fromRGB(255,255,255), TextSize=11, Parent=row})
        corner(3)
        resetBtn.MouseButton1Click:Connect(function()
            resetConfig()
            resetBtn.Text = "Deleted!"
            task.delay(1.2, function() resetBtn.Text = "Reset Config (delete save file)" end)
        end)
    end

    local infoLbl = new("TextLabel", {Size=UDim2.new(1,0,0,50), BackgroundTransparency=1, Font=Enum.Font.Gotham, TextWrapped=true, TextColor3=Colors.SubText, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left, Text="Auto-saves on every change. Add this script to executor's autoexec folder to reload on teleport.", Parent=R})
end

for _, t in pairs(Tabs) do
    task.spawn(function()
        while task.wait(0.3) do
            if not t.page.Visible then continue end
            local maxY = 0
            for _, c in ipairs(t.page:GetChildren()) do
                if c:IsA("Frame") and c.Visible then
                    local b = (c.AbsolutePosition.Y - t.page.AbsolutePosition.Y) + c.AbsoluteSize.Y
                    if b > maxY then maxY = b end
                end
            end
            t.page.CanvasSize = UDim2.new(0,0,0,maxY+16)
        end
    end)
end

--// LOAD SAVED CONFIG
task.spawn(function()
    task.wait(0.3)
    pcall(loadConfig)
    -- reapply skybox from loaded value
    pcall(function() applySkybox(Config.Skybox or "Default") end)
end)

--// UTIL
local function getCam() return workspace.CurrentCamera end

local function isVisible(part, targetChar)
    local cam = getCam()
    if not cam or not part or not targetChar then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, cam}
    local result = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    if result and result.Instance then return result.Instance:IsDescendantOf(targetChar) end
    return true
end

local function toScreen(cam, worldPos)
    local s, onScreen = cam:WorldToViewportPoint(worldPos)
    if not onScreen then return nil end
    if s.Z <= 0 then return nil end
    local vp = cam.ViewportSize
    if s.X < 0 or s.Y < 0 or s.X > vp.X or s.Y > vp.Y then return nil end
    return s
end

--// CHAMS
local ChamsCache = {}
local function destroyChams(player)
    local h = ChamsCache[player]
    if h then pcall(function() h:Destroy() end); ChamsCache[player] = nil end
end
local function createChams(player)
    if player == LP or ChamsCache[player] then return end
    local h = Instance.new("Highlight")
    h.Name = "crackbonChams"
    h.OutlineTransparency = 0
    h.Enabled = false
    h.Parent = (gethui and gethui()) or CoreGui
    ChamsCache[player] = h
end
local function updateChams(player)
    local h = ChamsCache[player]
    if not h then createChams(player); h = ChamsCache[player] end
    if not h then return end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local show = Config.Visuals.Chams and Config.Visuals.Enabled
        and player ~= LP and char and hum and hum.Health > 0
    if show and Config.Visuals.TeamCheck and sameTeam(player, LP) then show = false end
    if show and Config.Visuals.VisCheck then
        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if head and not isVisible(head, char) then show = false end
    end
    if show then
        h.Adornee = char
        h.FillColor = Config.Visuals.TeamColor and teamColor(player) or Config.Visuals.ChamsFill
        h.OutlineColor = Config.Visuals.ChamsOutline
        h.FillTransparency = Config.Visuals.ChamsTransparency
        h.DepthMode = Config.Visuals.ChamsThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.Enabled = true
    else
        h.Enabled = false; h.Adornee = nil
    end
end

--// ESP
local ESP = {cache = {}}
local BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local DRAW_OK = Drawing and Drawing.new and true or false

local function drawing(class, props)
    if not DRAW_OK then return nil end
    local ok, d = pcall(function() return Drawing.new(class) end)
    if not ok or not d then return nil end
    for k, v in pairs(props or {}) do pcall(function() d[k] = v end) end
    return reg(d)
end

local function getRig(char)
    if char:FindFirstChild("UpperTorso") then return "R15", BONES_R15 end
    if char:FindFirstChild("Torso") then return "R6", BONES_R6 end
    return nil, nil
end

local function createESP(player)
    if player == LP or ESP.cache[player] then return end
    if not DRAW_OK then return end
    local o = {}
    o.box      = drawing("Square", {Thickness=1, Filled=false, Color=Config.Visuals.Color, Visible=false, Transparency=1})
    o.boxFill  = drawing("Square", {Filled=true, Color=Config.Visuals.Color, Visible=false, Transparency=0.15})
    o.name     = drawing("Text", {Size=13, Center=true, Outline=true, Color=Color3.fromRGB(255,255,255), Visible=false, Font=2})
    o.distance = drawing("Text", {Size=12, Center=true, Outline=true, Color=Color3.fromRGB(200,200,200), Visible=false, Font=2})
    o.health   = drawing("Line", {Thickness=2, Color=Color3.fromRGB(0,255,0), Visible=false, Transparency=1})
    o.healthBg = drawing("Line", {Thickness=2, Color=Color3.fromRGB(0,0,0), Visible=false, Transparency=1})
    o.tracer   = drawing("Line", {Thickness=1, Color=Config.Visuals.Color, Visible=false, Transparency=1})
    o.headDot  = drawing("Circle", {Radius=3, Filled=true, Color=Config.Visuals.Color, Visible=false, Transparency=1})
    o.skeleton = {}
    for i = 1, #BONES_R15 do
        o.skeleton[i] = drawing("Line", {Thickness=1, Color=Color3.fromRGB(255,255,255), Visible=false, Transparency=1})
    end
    if not o.box or not o.name then return end
    ESP.cache[player] = o
end

local function destroyESP(player)
    local o = ESP.cache[player]
    if not o then return end
    ESP.cache[player] = nil
    for _, v in pairs(o) do
        if type(v) == "table" then for _, l in pairs(v) do removeDrawing(l) end
        else removeDrawing(v) end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.4); createESP(p); createChams(p) end)
end)
Players.PlayerRemoving:Connect(function(p) destroyESP(p); destroyChams(p) end)
for _, p in ipairs(Players:GetPlayers()) do createESP(p); createChams(p) end

task.spawn(function()
    while task.wait(1) do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                if not ESP.cache[p] then createESP(p) end
                if not ChamsCache[p] then createChams(p) end
            end
        end
    end
end)

local function updateOne(player, o)
    local cam = getCam()
    if not cam or not o or not o.box then return end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local render = true
    if not Config.Visuals.Enabled or player == LP or not char or not hum or not hrp or hum.Health <= 0
        or (Config.Visuals.TeamCheck and sameTeam(player, LP)) then render = false end
    if render then
        if (cam.CFrame.Position - hrp.Position).Magnitude > Config.Visuals.MaxDistance then render = false end
        if render and Config.Visuals.VisCheck and not isVisible(char:FindFirstChild("Head") or hrp, char) then render = false end
    end
    local topS, botS
    if render then
        local head = char:FindFirstChild("Head")
        local headPos = head and head.Position or (hrp.Position + Vector3.new(0,2.5,0))
        topS = toScreen(cam, headPos + Vector3.new(0,0.7,0))
        botS = toScreen(cam, hrp.Position - Vector3.new(0,3.0,0))
        if not topS or not botS then render = false end
    end
    if not render then return end
    local height = math.abs(topS.Y - botS.Y)
    local width  = height * 0.55 * (1 + Config.Visuals.BoxPadding)
    local x, y = topS.X - width/2, topS.Y
    local col = Config.Visuals.TeamColor and teamColor(player) or Config.Visuals.Color
    if Config.Visuals.Box and o.box then
        o.box.Visible = true; o.box.Color = col
        o.box.Size = Vector2.new(width, height); o.box.Position = Vector2.new(x, y)
        if o.boxFill and Config.Visuals.BoxFilled then
            o.boxFill.Visible = true; o.boxFill.Color = col
            o.boxFill.Size = Vector2.new(width, height); o.boxFill.Position = Vector2.new(x, y)
        end
    end
    if Config.Visuals.Name and o.name then
        o.name.Visible = true; o.name.Text = player.Name
        o.name.Position = Vector2.new(topS.X, y - 16); o.name.Color = col
    end
    if Config.Visuals.Distance and o.distance then
        local d = (cam.CFrame.Position - hrp.Position).Magnitude
        o.distance.Visible = true
        o.distance.Text = string.format("[%d]", math.floor(d))
        o.distance.Position = Vector2.new(topS.X, y + height + 2)
        o.distance.Color = Color3.fromRGB(230,230,230)
    end
    if Config.Visuals.Health and o.health and o.healthBg then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        o.healthBg.Visible = true
        o.healthBg.From = Vector2.new(x-4, y); o.healthBg.To = Vector2.new(x-4, y+height)
        o.health.Visible = true
        o.health.From = Vector2.new(x-4, y + height - height*pct)
        o.health.To   = Vector2.new(x-4, y + height)
        o.health.Color = Color3.fromRGB(255*(1-pct), 255*pct, 60)
    end
    if Config.Visuals.Tracer and o.tracer then
        o.tracer.Visible = true; o.tracer.Color = col
        o.tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        o.tracer.To   = Vector2.new(topS.X, y + height)
    end
    if Config.Visuals.HeadDot and o.headDot then
        local head = char:FindFirstChild("Head")
        if head then
            local hp = toScreen(cam, head.Position)
            if hp then
                o.headDot.Visible = true; o.headDot.Color = col
                o.headDot.Position = Vector2.new(hp.X, hp.Y)
            end
        end
    end
    if Config.Visuals.Skeleton and o.skeleton then
        local _, bones = getRig(char)
        if bones then
            for i, pair in ipairs(bones) do
                local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                local line = o.skeleton[i]
                if a and b and line then
                    local ap = toScreen(cam, a.Position)
                    local bp = toScreen(cam, b.Position)
                    if ap and bp then
                        line.Visible = true
                        line.From = Vector2.new(ap.X, ap.Y); line.To = Vector2.new(bp.X, bp.Y)
                        line.Color = col
                    end
                end
            end
        end
    end
end

local function updateESP()
    hideAll()
    for player, o in pairs(ESP.cache) do pcall(updateOne, player, o) end
    for player, _ in pairs(ChamsCache) do pcall(updateChams, player) end
end

--// TARGETING
local function pickPart(char, mode)
    if mode == "Head" then return char:FindFirstChild("Head") end
    if mode == "UpperTorso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    if mode == "LowerTorso" then return char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso") end
    local cam = getCam(); if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local best, bestD = nil, math.huge
    for _, name in ipairs({"Head","UpperTorso","LowerTorso","Torso","HumanoidRootPart"}) do
        local p = char:FindFirstChild(name)
        if p then
            local s = toScreen(cam, p.Position)
            if s then
                local d = (Vector2.new(s.X, s.Y) - center).Magnitude
                if d < bestD then bestD = d; best = p end
            end
        end
    end
    return best
end

local function scanFOV(fov, maxDist, teamCheck, visCheck, wallCheck, partMode)
    local cam = getCam(); if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local closest, closestFov = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character; if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then continue end
        if teamCheck and sameTeam(p, LP) then continue end
        if (cam.CFrame.Position - hrp.Position).Magnitude > maxDist then continue end
        local part = pickPart(char, partMode); if not part then continue end
        local s = toScreen(cam, part.Position); if not s then continue end
        local fovDist = (Vector2.new(s.X, s.Y) - center).Magnitude
        if fovDist > fov then continue end
        if (wallCheck or visCheck) and not isVisible(part, char) then continue end
        if fovDist < closestFov then
            closestFov = fovDist
            closest = {player=p, part=part, char=char}
        end
    end
    return closest
end

--// AIMBOT
local savedCamType = nil

local function applyAimbot()
    local cam = getCam()
    if not cam then return end

    if Config.Aimbot.ScriptableCamera then
        if Config.Aimbot.Enabled then
            if cam.CameraType ~= Enum.CameraType.Scriptable then
                savedCamType = cam.CameraType
                cam.CameraType = Enum.CameraType.Scriptable
            end
        else
            if savedCamType and cam.CameraType == Enum.CameraType.Scriptable then
                cam.CameraType = savedCamType
                savedCamType = nil
            end
        end
    end

    if not Config.Aimbot.Enabled then return end

    local t = scanFOV(
        Config.Aimbot.FOV, Config.Aimbot.MaxDistance,
        Config.Aimbot.TeamCheck, Config.Aimbot.VisCheck, Config.Aimbot.WallCheck,
        Config.Aimbot.TargetPart
    )
    if not t then return end

    local aimPos = t.part.Position + Config.Aimbot.Offset
    if Config.Aimbot.Prediction > 0 and t.part.AssemblyLinearVelocity then
        aimPos = aimPos + t.part.AssemblyLinearVelocity * Config.Aimbot.Prediction
    end
    cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, aimPos), Config.Aimbot.Smoothness)
end

--// TRIGGERBOT
local triggerBusy = false
local keyHeld = false

UserInputService.InputBegan:Connect(function(i)
    if inputMatchesBind(i, Config.Triggerbot.Bind) then keyHeld = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if inputMatchesBind(i, Config.Triggerbot.Bind) then keyHeld = false end
end)

task.spawn(function()
    while task.wait(0.05) do
        local b = Config.Triggerbot.Bind
        if b and b.kind == "key" then
            if UserInputService:IsKeyDown(b.value) then keyHeld = true end
        end
    end
end)

local function crosshairTarget()
    local cam = getCam(); if not cam then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character, cam}
    local result = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector*1000, params)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LP then
                if Config.Triggerbot.TeamCheck and sameTeam(plr, LP) then return nil end
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp and (cam.CFrame.Position - hrp.Position).Magnitude > Config.Triggerbot.MaxDistance then return nil end
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return {player=plr, part=result.Instance} end
            end
        end
    end
    return nil
end

local function findKeyTarget()
    return scanFOV(
        Config.Triggerbot.KeyFOV, Config.Triggerbot.MaxDistance,
        Config.Triggerbot.TeamCheck, Config.Triggerbot.VisCheck, false,
        "Head"
    )
end

local function findAutoTarget()
    if Config.Triggerbot.Mode == "FOV" then
        return scanFOV(
            Config.Triggerbot.FOV, Config.Triggerbot.MaxDistance,
            Config.Triggerbot.TeamCheck, Config.Triggerbot.VisCheck, false,
            Config.Triggerbot.TargetPart
        )
    end
    return crosshairTarget()
end

local function fireOnce()
    local cam = getCam(); if not cam then return end
    local vim = game:GetService("VirtualInputManager")
    pcall(function() vim:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, true, game, 0) end)
    task.wait(Config.Triggerbot.ClickDuration / 1000)
    pcall(function() vim:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 0) end)
end

local function doFire()
    if triggerBusy then return end
    if math.random(1, 100) > Config.Triggerbot.Hitchance then return end
    triggerBusy = true
    task.spawn(function()
        task.wait(Config.Triggerbot.Delay / 1000)
        if Config.Triggerbot.Burst then
            for _ = 1, Config.Triggerbot.BurstCount do
                if not Config.Triggerbot.Enabled then break end
                fireOnce()
            end
        else fireOnce() end
        task.wait(0.05); triggerBusy = false
    end)
end

local function applyTrigger()
    if not Config.Triggerbot.Enabled then return end
    if Config.Triggerbot.UseKey then
        if not keyHeld then return end
        local t = findKeyTarget(); if not t then return end
        local cam = getCam(); if not cam then return end
        local aimPos = t.part.Position
        if Config.Triggerbot.KeyPrediction > 0 and t.part.AssemblyLinearVelocity then
            aimPos = aimPos + t.part.AssemblyLinearVelocity * Config.Triggerbot.KeyPrediction
        end
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, aimPos), Config.Triggerbot.KeyAimSmoothness)
        doFire()
    else
        local t = findAutoTarget(); if not t then return end
        doFire()
    end
end

--// DRAWINGS
local aimFovCircle     = drawing("Circle", {Thickness=2, Filled=false, Color=Config.Aimbot.FOVColor,    Transparency=0.7, Visible=false, NumSides=90})
local triggerFovCircle = drawing("Circle", {Thickness=2, Filled=false, Color=Config.Triggerbot.FOVColor, Transparency=0.7, Visible=false, NumSides=90})
local keyFovCircle     = drawing("Circle", {Thickness=2, Filled=false, Color=Color3.fromRGB(255,180,60), Transparency=0.5, Visible=false, NumSides=90})
local snapline         = drawing("Line",   {Thickness=1, Color=Color3.fromRGB(255,255,255), Transparency=0.6, Visible=false})

--// MAIN LOOP
local aimErrPrinted = false

local function tickAimbot()
    local ok, err = pcall(applyAimbot)
    if not ok and not aimErrPrinted then
        aimErrPrinted = true
        warn("[크랙본 by R0W] Aimbot error: " .. tostring(err))
    end
end

local function tickDrawings()
    pcall(updateESP)
    local cam = getCam(); if not cam then return end
    local cx, cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2

    if aimFovCircle and Config.Aimbot.Enabled and Config.Aimbot.DrawFOV then
        aimFovCircle.Visible = true
        aimFovCircle.Position = Vector2.new(cx, cy)
        aimFovCircle.Radius = Config.Aimbot.FOV
        aimFovCircle.Color = Config.Aimbot.FOVColor
    end
    if triggerFovCircle and Config.Triggerbot.Enabled and Config.Triggerbot.DrawFOV
        and not Config.Triggerbot.UseKey and Config.Triggerbot.Mode == "FOV" then
        triggerFovCircle.Visible = true
        triggerFovCircle.Position = Vector2.new(cx, cy)
        triggerFovCircle.Radius = Config.Triggerbot.FOV
        triggerFovCircle.Color = Config.Triggerbot.FOVColor
    end
    if keyFovCircle and Config.Triggerbot.Enabled and Config.Triggerbot.UseKey then
        keyFovCircle.Visible = true
        keyFovCircle.Position = Vector2.new(cx, cy)
        keyFovCircle.Radius = Config.Triggerbot.KeyFOV
    end
    if snapline and Config.Aimbot.Enabled and Config.Aimbot.Snapline then
        local t = scanFOV(
            Config.Aimbot.FOV, Config.Aimbot.MaxDistance,
            Config.Aimbot.TeamCheck, Config.Aimbot.VisCheck, Config.Aimbot.WallCheck,
            Config.Aimbot.TargetPart
        )
        if t then
            local s = toScreen(cam, t.part.Position)
            if s then
                snapline.Visible = true
                snapline.From = Vector2.new(cx, cy)
                snapline.To   = Vector2.new(s.X, s.Y)
            end
        end
    end
end

RunService:BindToRenderStep("crackbonAimbot",  Enum.RenderPriority.Camera.Value + 1, tickAimbot)
RunService:BindToRenderStep("crackbonDraw",    Enum.RenderPriority.Camera.Value + 2, tickDrawings)
RunService:BindToRenderStep("crackbonTrigger", Enum.RenderPriority.Camera.Value + 3, function()
    pcall(applyTrigger)
end)

UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.F1 then Main.Visible = not Main.Visible end
    if i.KeyCode == Enum.KeyCode.F2 then purgeAll() end
end)

if not DRAW_OK then warn("[크랙본 by R0W] No Drawing API — ESP won't render.") end
if not Save.canSave then warn("[크랙본 by R0W] writefile/readfile not supported — config won't persist.") end

print("[크랙본 by R0W] loaded — F1 UI, F2 purge.")
