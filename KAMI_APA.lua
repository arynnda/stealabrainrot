repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
print("KAMI•APA")

-- ======================================================
-- SERVICES
-- ======================================================
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- ======================================================
-- CONFIG
-- ======================================================
getgenv().TARGET_UNITS = getgenv().TARGET_UNITS or {}
getgenv().GRAB_RADIUS = getgenv().GRAB_RADIUS or 8
getgenv().FPS_CAP = getgenv().FPS_CAP or 20
getgenv().BLACK_SCREEN = getgenv().BLACK_SCREEN ~= false
getgenv().WEBHOOK_URL = getgenv().WEBHOOK_URL or ""

local SPIN_INTERVAL = 5

-- ======================================================
-- FPS CAP (SAFE)
-- ======================================================
if typeof(setfpscap) == "function" then
	task.spawn(function()
		while true do
			setfpscap(getgenv().FPS_CAP)
			task.wait(1)
		end
	end)
end

-- ======================================================
-- EXTREME DARK LIGHTING
-- ======================================================
task.spawn(function()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.Brightness = 0
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		Lighting.OutdoorAmbient = Color3.new(0,0,0)
		Lighting.Ambient = Color3.new(0,0,0)
		Lighting.ClockTime = 0
		Lighting.ExposureCompensation = -4
		Lighting.FogColor = Color3.new(0,0,0)
		Lighting.FogStart = 0
		Lighting.FogEnd = 60
	end)

	for _,v in ipairs(Lighting:GetChildren()) do
		if v:IsA("PostEffect") then
			v:Destroy()
		end
	end
end)

-- ======================================================
-- BASIC
-- ======================================================
local function char()
	return player.Character
end

local function hrp()
	local c = char()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local firePrompt = typeof(fireproximityprompt) == "function"
	and fireproximityprompt
	or function() end

local function webhook(msg)
	if getgenv().WEBHOOK_URL == "" then return end
	pcall(function()
		HttpService:PostAsync(
			getgenv().WEBHOOK_URL,
			HttpService:JSONEncode({content = msg}),
			Enum.HttpContentType.ApplicationJson
		)
	end)
end

-- ======================================================
-- TARGET CHECK
-- ======================================================
local function isTarget(model)
	local idx = model:GetAttribute("Index")
	if not idx then return false end
	for _,v in ipairs(getgenv().TARGET_UNITS) do
		if v == idx then return true end
	end
	return false
end

-- ======================================================
-- STATE
-- ======================================================
local currentTarget
local pendingName
local lastMoney

-- ======================================================
-- MONEY DETECT
-- ======================================================
task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	for _,v in ipairs(stats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			lastMoney = v.Value
			v.Changed:Connect(function(nv)
				if nv < lastMoney and pendingName then
					webhook("🛒 Bought: "..pendingName)
					currentTarget = nil
					pendingName = nil
				end
				lastMoney = nv
			end)
			break
		end
	end
end)

-- ======================================================
-- TARGET SPAWN
-- ======================================================
workspace.DescendantAdded:Connect(function(obj)
	if currentTarget then return end
	if obj:IsA("Model") and isTarget(obj) then
		currentTarget = obj
		pendingName = obj:GetAttribute("Index") or obj.Name
	end
end)

-- ======================================================
-- AUTO PROMPT
-- ======================================================
ProximityPromptService.PromptShown:Connect(function(prompt)
	if currentTarget and prompt:IsDescendantOf(currentTarget) then
		firePrompt(prompt)
	end
end)

-- ======================================================
-- MOVE LOOP
-- ======================================================
task.spawn(function()
	while true do
		if currentTarget then
			local part = currentTarget:FindFirstChildWhichIsA("BasePart")
			local h = humanoid()
			local r = hrp()
			if part and h and r then
				if (r.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
					h:MoveTo(part.Position)
				end
			end
		end
		task.wait(0.6)
	end
end)

-- ======================================================
-- AUTO SPIN
-- ======================================================
task.spawn(function()
	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local ok, Net = pcall(require, Packages:WaitForChild("Net"))
	if not ok then return end

	local SpinEvent = Net:RemoteEvent("ChristmasEventService/Spin")
	local last = 0

	while true do
		if tick() - last >= SPIN_INTERVAL then
			pcall(function()
				SpinEvent:FireServer()
			end)
			last = tick()
		end
		task.wait(0.5)
	end
end)

-- ======================================================
-- ANTI AFK
-- ======================================================
player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ======================================================
-- BLACK SCREEN + FPS + F5
-- ======================================================
local gui, fpsConn
local enabled = getgenv().BLACK_SCREEN

local function enableBlack()
	if gui then return end
	gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false

	local bg = Instance.new("Frame", gui)
	bg.Size = UDim2.new(1,0,1,0)
	bg.BackgroundColor3 = Color3.new(0,0,0)
	bg.BorderSizePixel = 0

	local title = Instance.new("TextLabel", gui)
	title.Size = UDim2.new(0,300,0,40)
	title.Position = UDim2.new(0.5,-150,0,10)
	title.BackgroundTransparency = 1
	title.Text = "KAMI•APA"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 26
	title.TextColor3 = Color3.new(1,1,1)

	local fps = Instance.new("TextLabel", gui)
	fps.Size = UDim2.new(0,200,0,30)
	fps.Position = UDim2.new(0.5,-100,0,52)
	fps.BackgroundTransparency = 1
	fps.TextColor3 = Color3.new(1,1,1)
	fps.Font = Enum.Font.Gotham
	fps.TextSize = 18

	local frames,last=0,tick()
	fpsConn = RunService.RenderStepped:Connect(function()
		frames+=1
		if tick()-last>=1 then
			fps.Text="FPS : "..frames
			frames=0
			last=tick()
		end
	end)
end

local function disableBlack()
	if fpsConn then fpsConn:Disconnect() fpsConn=nil end
	if gui then gui:Destroy() gui=nil end
end

if enabled then enableBlack() end

UserInputService.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode==Enum.KeyCode.F5 then
		enabled = not enabled
		if enabled then enableBlack() else disableBlack() end
	end
end)
