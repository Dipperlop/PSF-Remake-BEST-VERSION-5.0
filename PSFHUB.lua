-- PSF Remake 4.1 — Complete All-in-One UI + Script Executor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Ensure data storage
if not player:FindFirstChild("PSFRemakeData") then
    local folder = Instance.new("Folder", player)
    folder.Name = "PSFRemakeData"
    local scriptsVal = Instance.new("StringValue", folder)
    scriptsVal.Name = "Scripts"
    scriptsVal.Value = "[]"
    local settingsVal = Instance.new("StringValue", folder)
    settingsVal.Name = "Settings"
    settingsVal.Value = "{}"
end

local dataFolder = player:FindFirstChild("PSFRemakeData")
local scriptsValue = dataFolder:FindFirstChild("Scripts")
local settingsValue = dataFolder:FindFirstChild("Settings")

-- JSON decode helper
local function decodeJSON(s,fallback)
    local ok,res = pcall(function() return HttpService:JSONDecode(s) end)
    if ok and type(res)=="table" then return res end
    return fallback
end

local savedScripts = decodeJSON(scriptsValue.Value,nil)
local demoScripts = savedScripts and #savedScripts>0 and savedScripts or {
    {name="Hello", code="print('Hello from PSF')"},
    {name="Timer", code="for i=1,5 do print('tick', i) wait(1) end"},
}

local savedSettings = decodeJSON(settingsValue.Value,{selected=1})

-- UI Root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PSFRemakeUI"
screenGui.ResetOnSpawn=false
screenGui.Parent = PlayerGui

-- Auto scale
local uiScale = Instance.new("UIScale",screenGui)
uiScale.Name="AutoUIScale"
local function updateScale()
    local s = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800
    local scale = math.clamp(s/900,0.8,1.2)
    uiScale.Scale=scale
end
RunService.RenderStepped:Connect(updateScale)
updateScale()

-- Main container
local main = Instance.new("Frame",screenGui)
main.Name="Main"
main.AnchorPoint=Vector2.new(0.5,0.5)
main.Position=UDim2.new(0.5,0,0.5,0)
main.Size=UDim2.new(0.92,0,0.78,0)
main.BackgroundColor3=Color3.fromRGB(18,18,18)
main.BorderSizePixel=0
main.ClipsDescendants=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)

-- Draggable
local dragging = false
local dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true
        dragStart=input.Position
        startPos=main.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragging=false
            end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
        dragInput=input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input==dragInput then
        local delta=input.Position-dragStart
        main.Position=startPos+UDim2.new(0,delta.X,0,delta.Y)
    end
end)

-- Header
local header = Instance.new("Frame",main)
header.Name="Header"
header.Size=UDim2.new(1,0,0,46)
header.BackgroundTransparency=1

local title=Instance.new("TextLabel",header)
title.Text="PSF Remake 4.1"
title.Font=Enum.Font.GothamBold
title.TextSize=20
title.TextColor3=Color3.fromRGB(240,240,240)
title.BackgroundTransparency=1
title.Position=UDim2.new(0,16,0,6)
title.Size=UDim2.new(0.5,0,1,0)
title.TextXAlignment=Enum.TextXAlignment.Left

-- Toolbar
local toolbar=Instance.new("Frame",header)
toolbar.AnchorPoint=Vector2.new(1,0)
toolbar.Position=UDim2.new(1,-12,0,6)
toolbar.BackgroundTransparency=1
toolbar.Size=UDim2.new(0,360,1,0)
local function makeBtn(parent,text,sizeX)
    local b=Instance.new("TextButton",parent)
    b.Text=text
    b.Font=Enum.Font.Gotham
    b.TextSize=14
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.AutoButtonColor=true
    b.BackgroundColor3=Color3.fromRGB(38,38,38)
    b.Size=UDim2.new(0,sizeX or 72,0,30)
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end

local runBtn=makeBtn(toolbar,"Run",72)
local newBtn=makeBtn(toolbar,"New",72)
local delBtn=makeBtn(toolbar,"Delete",72)
local clearBtn=makeBtn(toolbar,"Clear",72)
local exportBtn=makeBtn(toolbar,"Export",72)
local tbLayout=Instance.new("UIListLayout",toolbar)
tbLayout.FillDirection=Enum.FillDirection.Horizontal
tbLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right
tbLayout.SortOrder=Enum.SortOrder.LayoutOrder
tbLayout.Padding=UDim.new(0,8)
toolbar.Size=UDim2.new(0,(72+8)*5,1,0)

-- Body
local body=Instance.new("Frame",main)
body.Position=UDim2.new(0,12,0,56)
body.Size=UDim2.new(1,-24,1,-68)
body.BackgroundTransparency=1

-- Left panel: scripts list
local left=Instance.new("Frame",body)
left.Size=UDim2.new(0.32,-8,1,0)
left.Position=UDim2.new(0,0,0,0)
left.BackgroundTransparency=1

local leftHeader=Instance.new("TextLabel",left)
leftHeader.Text="Scripts"
leftHeader.Font=Enum.Font.GothamSemibold
leftHeader.TextSize=16
leftHeader.TextColor3=Color3.fromRGB(230,230,230)
leftHeader.BackgroundTransparency=1
leftHeader.Size=UDim2.new(1,0,0,0.06*body.AbsoluteSize.Y)
leftHeader.Position=UDim2.new(0,0,0,0)

local listFrame=Instance.new("ScrollingFrame",left)
listFrame.Position=UDim2.new(0,0,0.06,8)
listFrame.Size=UDim2.new(1,0,0.94,-8)
listFrame.BackgroundColor3=Color3.fromRGB(24,24,24)
listFrame.BorderSizePixel=0
listFrame.ScrollBarThickness=8
local listCorner=Instance.new("UICorner",listFrame)
listCorner.CornerRadius=UDim.new(0,8)
local listLayout=Instance.new("UIListLayout",listFrame)
listLayout.Padding=UDim.new(0,8)
listLayout.SortOrder=Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

-- Right panel: editor + console
local right=Instance.new("Frame",body)
right.Size=UDim2.new(0.68,0,1,0)
right.Position=UDim2.new(0.32,8,0,0)
right.BackgroundTransparency=1

local editorBox=Instance.new("TextBox",right)
editorBox.MultiLine=true
editorBox.ClearTextOnFocus=false
editorBox.TextWrapped=false
editorBox.TextXAlignment=Enum.TextXAlignment.Left
editorBox.TextYAlignment=Enum.TextYAlignment.Top
editorBox.Font=Enum.Font.Code
editorBox.TextSize=16
editorBox.Text="-- Выберите или создайте скрипт\n"
editorBox.BackgroundColor3=Color3.fromRGB(14,14,14)
editorBox.TextColor3=Color3.fromRGB(240,240,240)
editorBox.Size=UDim2.new(1,0,0.64,0)
editorBox.Position=UDim2.new(0,0,0.06,8)
Instance.new("UICorner",editorBox).CornerRadius=UDim.new(0,8)

local consoleFrame=Instance.new("ScrollingFrame",right)
consoleFrame.Position=UDim2.new(0,0,0.73,8)
consoleFrame.Size=UDim2.new(1,0,0.27,-8)
consoleFrame.BackgroundColor3=Color3.fromRGB(12,12,12)
consoleFrame.BorderSizePixel=0
consoleFrame.ScrollBarThickness=8
local consoleCorner=Instance.new("UICorner",consoleFrame)
consoleCorner.CornerRadius=UDim.new(0,8)

local consoleText=Instance.new("TextLabel",consoleFrame)
consoleText.Size=UDim2.new(1,-16,0,0)
consoleText.Position=UDim2.new(0,8,0,8)
consoleText.BackgroundTransparency=1
consoleText.TextXAlignment=Enum.TextXAlignment.Left
consoleText.TextYAlignment=Enum.TextYAlignment.Top
consoleText.Font=Enum.Font.Code
consoleText.TextSize=14
consoleText.TextColor3=Color3.fromRGB(220,220,220)
consoleText.Text=""
consoleText.TextWrapped=true
consoleText.AutomaticSize=Enum.AutomaticSize.Y

-- Collapse/Expand button (bottom-left)
local collapsed=false
local rotateBtn=Instance.new("ImageButton",screenGui)
rotateBtn.Size=UDim2.new(0,40,0,40)
rotateBtn.Position=UDim2.new(0,10,1,-50)
rotateBtn.AnchorPoint=Vector2.new(0,0)
rotateBtn.Image="rbxassetid://93738238823550"
rotateBtn.BackgroundTransparency=1
rotateBtn.Rotation=0
rotateBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
end)

-- Helper functions
local function appendConsole(line)
    consoleText.Text=consoleText.Text..tostring(line).."\n"
    consoleText.Size=UDim2.new(1,-16,0,consoleText.TextBounds.Y+16)
    consoleFrame.CanvasSize=UDim2.new(0,0,0,consoleText.AbsoluteSize.Y+24)
    consoleFrame.CanvasPosition=Vector2.new(0,math.max(0,consoleText.AbsoluteSize.Y-consoleFrame.AbsoluteSize.Y))
end
local function saveScripts()
    scriptsValue.Value=HttpService:JSONEncode(demoScripts)
end
local function rebuildList()
    for _,child in pairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for i,s in ipairs(demoScripts) do
        local btn=Instance.new("TextButton",listFrame)
        btn.Size=UDim2.new(1,-16,0,40)
        btn.Position=UDim2.new(0,8,0,0)
        btn.BackgroundColor3=Color3.fromRGB(28,28,28)
        btn.TextColor3=Color3.fromRGB(235,235,235)
        btn.Font=Enum.Font.Gotham
        btn.TextSize=14
        btn.Text=s.name
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
        btn.LayoutOrder=i
        btn.MouseButton1Click:Connect(function()
            savedSettings.selected=i
            editorBox.Text=s.code or ""
            appendConsole("Selected: "..s.name)
            saveScripts()
        end)
    end
    listFrame.CanvasSize=UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+16)
end
rebuildList()

-- Toolbar buttons
runBtn.MouseButton1Click:Connect(function()
    local sel=savedSettings.selected or 1
    local s=demoScripts[sel]
    if s then
        s.code=editorBox.Text
        saveScripts()
        appendConsole("Running: "..s.name)
        local ok,f=pcall(loadstring,s.code)
        if ok and type(f)=="function" then
            local success,err=pcall(f)
            if not success then appendConsole("Error: "..tostring(err)) end
        else
            appendConsole("Compile error.")
        end
    else
        appendConsole("No script selected.")
    end
end)
newBtn.MouseButton1Click:Connect(function()
    table.insert(demoScripts,{name="New Script "..#demoScripts+1,code="-- new script\n"})
    savedSettings.selected=#demoScripts
    rebuildList()
    editorBox.Text=demoScripts[#demoScripts].code
    saveScripts()
    appendConsole("Created new script.")
end)
delBtn.MouseButton1Click:Connect(function()
    local sel=savedSettings.selected
    if sel and demoScripts[sel] then
        table.remove(demoScripts,sel)
        savedSettings.selected=math.clamp(sel-1,1,math.max(1,#demoScripts))
        rebuildList()
        editorBox.Text=demoScripts[savedSettings.selected] and demoScripts[savedSettings.selected].code or ""
        saveScripts()
        appendConsole("Deleted script.")
    else appendConsole("No script selected to delete.") end
end)
clearBtn.MouseButton1Click:Connect(function()
    consoleText.Text=""
    consoleFrame.CanvasSize=UDim2.new(0,0,0,0)
end)
exportBtn.MouseButton1Click:Connect(function()
    appendConsole("Export JSON:")
    appendConsole(HttpService:JSONEncode(demoScripts))
end)

-- Auto-save editor
local autosaveTicker=0
editorBox:GetPropertyChangedSignal("Text"):Connect(function() autosaveTicker=0 end)
RunService.Heartbeat:Connect(function(dt)
    autosaveTicker=autosaveTicker+dt
    if autosaveTicker>1 then
        autosaveTicker=0
        local sel=savedSettings.selected
        if sel and demoScripts[sel] then
            demoScripts[sel].code=editorBox.Text
            saveScripts()
        end
    end
end)

-- Restore last selected
local sel=savedSettings.selected or 1
editorBox.Text=demoScripts[sel] and demoScripts[sel].code or ""
appendConsole("PSF Remake 4.1 ready. Select script and press Run.")

-- Animation loop
local animSpeed=5
local colorTime=0
RunService.RenderStepped:Connect(function(dt)
    -- Rotate collapse button
    rotateBtn.Rotation=(rotateBtn.Rotation+dt*90)%360

    -- Collapse/expand main UI
    local targetScale=collapsed and 0 or 1
    local currentX,currentY=main.Size.X.Scale,main.Size.Y.Scale
    local scaleX=currentX+(targetScale-currentX)*dt*animSpeed
    local scaleY=currentY+(targetScale-currentY)*dt*animSpeed
    main.Size=UDim2.new(scaleX,0,scaleY,0)
    main.ClipsDescendants=scaleY<0.01
    body.Visible=scaleY>0.01
    main.BackgroundTransparency=1-scaleY

    -- Smooth color shift
    colorTime=colorTime+dt
    local cv=(math.sin(colorTime)+1)/2
    local r=18+(240-18)*cv
    local g=18+(240-18)*cv
    local b=18+(240-18)*cv
    main.BackgroundColor3=Color3.fromRGB(r,g,b)
end)
