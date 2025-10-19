local plr = game.Players.LocalPlayer
local nvgevent = game.ReplicatedStorage:WaitForChild("nvg")
local nvgremoveevent = game.ReplicatedStorage:WaitForChild("removenvg")
local irevent = game.ReplicatedStorage:WaitForChild("ir")
local actionservice = game:GetService("ContextActionService")
local tweenservice = game:GetService("TweenService")
local colorcorrection = Instance.new("ColorCorrectionEffect")
colorcorrection.Parent = game.Lighting
colorcorrection.Name = "NVG_ColorCorrection"
local UserInputService = game:GetService("UserInputService")
local bloom = Instance.new("BloomEffect")
bloom.Parent = game.Lighting
bloom.Intensity = 1
bloom.Size = 24
bloom.Threshold = 2
local DOF = Instance.new("DepthOfFieldEffect")
DOF.Parent = game.Lighting
DOF.FarIntensity = 0
DOF.FocusDistance = 0
DOF.InFocusRadius = 0
DOF.NearIntensity = 0

-- Import Vertical Lift Module
local VerticalLift
local success, result = pcall(function()
	return require(script.Parent:WaitForChild("NVGVerticalLift"))
end)

if success then
	VerticalLift = result
	print("NVGVerticalLift module loaded successfully")
else
	warn("Failed to load NVGVerticalLift module:", result)
	VerticalLift = nil
end

local defexposure = game.Lighting.ExposureCompensation

local nvg
local onanim
local gui
local offanim
local config
local onremoved
local setting
local helmet
local verticalLiftSystem = nil

-- Missing variable declarations
local animating = false
local nvgactive = false
local UISConnection

function removehelmet()
	if plr.Character then
		animating = false
		togglenvg(false)
		nvgevent:FireServer(nvgactive)
		actionservice:UnbindAction("nvgtoggle")
		if gui then
			gui:Destroy()
		end
		if plr.PlayerGui:FindFirstChild("IR_GUI") then
			plr.PlayerGui:FindFirstChild("IR_GUI"):Destroy()
		end
		if helmet then
			nvgremoveevent:FireServer(helmet)
		end
		if verticalLiftSystem then
			verticalLiftSystem:Destroy()
			verticalLiftSystem = nil
		end
	end
end

function fix()
	for _,v in pairs(game.Players:GetChildren()) do
		if v:IsA("Player") then
			for _,object in pairs(v.Character:GetDescendants()) do
				if object.Name == "StrobePart" then
					object.PointLight.Enabled = false
					object.BillboardGui.Enabled = false	
				end
			end
		end
	end
end

-- Initialize Vertical Lift System
function initializeVerticalLift()
	if helmet and gui and VerticalLift then
		local success, result = pcall(function()
			verticalLiftSystem = VerticalLift.new(helmet, gui)
		end)
		
		if success then
			print("Vertical Lift System initialized successfully")
		else
			warn("Failed to initialize Vertical Lift System:", result)
		end
	else
		if not VerticalLift then
			warn("VerticalLift module not available")
		elseif not helmet then
			warn("Helmet not found for vertical lift")
		elseif not gui then
			warn("GUI not found for vertical lift")
		end
	end
end

function oncharadded(newchar)
	newchar:WaitForChild("Humanoid").Died:connect(function()
		removehelmet()
		fix()
	end)
	newchar.ChildAdded:connect(function(child)
		local removebutton
		if child.Name == "NODs" then
			helmet = child
			gui = Instance.new("ScreenGui")
			gui.IgnoreGuiInset = true

			removebutton = Instance.new("TextButton")
			removebutton.Text = "Remove NODs"
			removebutton.Size = UDim2.new(.05,0,.035,0)
			removebutton.TextColor3 = Color3.new(.75,.75,.75)
			removebutton.Position = UDim2.new(.1,0,.3,0)
			removebutton.BackgroundTransparency = .45
			removebutton.BackgroundColor3 = Color3.fromRGB(124, 52, 38)
			removebutton.Font = Enum.Font.SourceSansBold
			removebutton.TextScaled = true
			removebutton.MouseButton1Down:connect(removehelmet)

			removebutton.Parent = gui
			gui.Parent = plr.PlayerGui
			
			-- Initialize vertical lift system when helmet is equipped
			initializeVerticalLift()

			onremoved = child.AncestryChanged:Connect(function(_, parent)
				if not parent then
					removehelmet()
				end
			end)

		end
		local newnvg = child:WaitForChild("Up",.5)
		if newnvg and newnvg:WaitForChild("Mounted").Value == false then
			nvg = newnvg
		elseif newnvg and newnvg.Mounted.Value == true then
				nvg = newnvg
				config = require(nvg:WaitForChild("AUTO_CONFIG"))
				setting = nvg:WaitForChild("NVG_Settings")


				local noise = Instance.new("ImageLabel")
				noise.BackgroundTransparency = 1
				noise.ImageTransparency = 1

				local overlay = noise:Clone()
				overlay.Image = "rbxassetid://"..setting.OverlayImage.Value
				if overlay.Image == "rbxassetid://15964793457" then
					overlay.ImageColor3 = setting.OverlayColor.Value
				end
				overlay.Size = UDim2.new(1,0,1,0)
				overlay.Name = "Overlay"

				local buttonpos = setting.RemoveButtonPosition.Value
				removebutton.Position = UDim2.new(buttonpos.X,0,buttonpos.Y,0)

				noise.Name = "Noise"
				--noise.AnchorPoint = Vector2.new(0,0)
				--noise.Position = UDim2.new(0,0,0,0)
				noise.Size = UDim2.new(1,0,1.5,0)


				noise.Parent = gui
				overlay.Parent = gui

				local info = config.tweeninfo

				local function addtweens(base,extra)
					if extra then
						for _,tween in pairs(extra)do
							table.insert(base,tween)
						end
					end
				end

				--plr.Character.NODs.Up.twistjoint.Changed:Connect(function()
				--	if plr.Character.NODs.Up.twistjoint.C0 == plr.Character.NODs.Up.downvalue.Value then
				--		if plr.Character.NODs:FindFirstChild("Light1") then
				--			plr.Character.NODs.Light1.SpotLight.Enabled = true
				--		end
				--		if plr.Character.NODs:FindFirstChild("Light2") then
				--			plr.Character.NODs.Light2.SpotLight.Enabled = true
				--		end
				--	else
				--		if plr.Character.NODs:FindFirstChild("Light1") then
				--			plr.Character.NODs.Light1.SpotLight.Enabled = false
				--		end
				--		if plr.Character.NODs:FindFirstChild("Light2") then
				--			plr.Character.NODs.Light2.SpotLight.Enabled = false
				--		end
				--	end
				--end)

				onanim = config.onanim
				offanim = config.offanim

				on_overlayanim = {
					tweenservice:Create(game.Lighting,info,{ExposureCompensation = setting.Exposure.Value}),
					tweenservice:Create(colorcorrection,info,{Brightness = setting.OverlayBrightness.Value,Contrast = .8,Saturation = -1,TintColor = setting.OverlayColor.Value}),
					tweenservice:Create(bloom,info,{Intensity = 0.45,Size = 500,Threshold = 2.371}),
					tweenservice:Create(DOF,info,{FarIntensity = 0.075,FocusDistance = 12.5,InFocusRadius = 0, NearIntensity = 0.313}),
					tweenservice:Create(gui.Overlay,info,{ImageTransparency = 0}),
					tweenservice:Create(gui.Noise,info,{ImageTransparency = 0}),

				}


				off_overlayanim = {
					tweenservice:Create(game.Lighting,info,{ExposureCompensation = defexposure}),
					tweenservice:Create(colorcorrection,info,{Brightness = 0,Contrast = 0,Saturation = 0,TintColor = Color3.fromRGB(255, 255, 255)}),
					tweenservice:Create(bloom,info,{Intensity = 1,Size = 24,Threshold = 2}),
					tweenservice:Create(DOF,info,{FarIntensity = 0,FocusDistance = 0,InFocusRadius = 0, NearIntensity = 0}),
					tweenservice:Create(gui.Overlay,info,{ImageTransparency = 1}),
					tweenservice:Create(gui.Noise,info,{ImageTransparency = 1})
				}

				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed then return end

					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.N then
						togglenvg(not nvgactive)
					end
				end)
				--actionservice:BindAction("nvgtoggle",function() togglenvg(not nvgactive) return Enum.ContextActionResult.Pass end, true, Enum.KeyCode.N)
			end
		end
	end)
end

plr.CharacterAdded:connect(oncharadded)

local oldchar = workspace:FindFirstChild(plr.Name)
if oldchar then
	oncharadded(oldchar)
end


function playtween(tweentbl)
	spawn(function()
		for _,step in pairs(tweentbl) do
			if typeof(step) == "number" then
				wait(step)
			else
				step:Play()
			end
		end
	end)
end

function applyprops(obj,props)
	for propname,val in pairs(props)do
		obj[propname] = val
	end
end



function cycle(grain)
	local label = gui.Noise
	local source = grain.src
	local newframe
	repeat newframe = source[math.random(1, #source)]; 
	until newframe ~= grain.last 
	label.Image = 'rbxassetid://'..newframe
	local rand = math.random(230,255)
	label.Position = UDim2.new(math.random(.4,.6),0,math.random(.4,.6),0)
	label.ImageColor3 = Color3.fromRGB(rand,rand,rand)
	grain.last = newframe
end


function togglenvg(bool)
	if nvg then
		if nvg:FindFirstChild("Mounted") and nvg:FindFirstChild("Mounted").Value == false then
			return
		end
	end
	if not animating and nvg then
		if gui:FindFirstChild("TextButton") then
			gui.TextButton.Visible = not bool
		end
		animating = true
		nvgactive = bool
		nvgevent:FireServer(nvgactive)

		if bool == true then
			task.delay(0.5,function()
				if nvg.Parent ~= nil then
					if nvg.Parent:FindFirstChild("Light1") then
						nvg.Parent.Light1.SpotLight.Enabled = true
					end
					if nvg.Parent:FindFirstChild("Light2") then
						nvg.Parent.Light2.SpotLight.Enabled = true
					end
				end
			end)
		else
			task.delay(0.3,function()
				if nvg.Parent ~= nil then
					if nvg.Parent:FindFirstChild("Light1") then
						nvg.Parent.Light1.SpotLight.Enabled = false
					end
					if nvg.Parent:FindFirstChild("Light2") then
						nvg.Parent.Light2.SpotLight.Enabled = false
					end
				end
			end)
		end

		if config.lens then
			config.lens.Material = bool and "Neon" or "Glass"
			if plr.PlayerGui:FindFirstChild("IR_GUI") then
				plr.PlayerGui.IR_GUI.TextButton.Visible = false
			end
		end
		if bool then
			playtween(onanim)
			delay(.75,function()
				playtween(on_overlayanim)
				spawn(function()
					while nvgactive do
						task.wait(0.5)
						--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
						--	if v:IsA("SurfaceLight") or v:IsA("SpotLight") or v:IsA("PointLight") then
						--		if v:FindFirstChild("IRYES") then
						--			v.Brightness = v.BrightnessVal.Value
						--			if v.Parent:FindFirstChild("BillboardGui") then
						--				v.Parent.BillboardGui.Enabled = true
						--			end
						--		end
						--	end
						--end

						--for _,v in pairs(game.Workspace:GetChildren()) do
						--	if v.Name == "IRPARTv" and v.Material == Enum.Material.Plastic then
						--		v.Material = Enum.Material.Neon
						--	end

						--	if v:FindFirstChild("Muzzle") then
						--		for _,g in pairs(v:GetDescendants()) do
						--			if g:IsA("SurfaceLight") or g:IsA("SpotLight") or g:IsA("PointLight") then
						--				if g:FindFirstChild("IRYES") then
						--					g.Brightness = g.BrightnessVal.Value
						--					if g.Parent:FindFirstChild("BillboardGui") then
						--						g.Parent.BillboardGui.Enabled = true
						--					end
						--				end
						--			end
						--		end
						--	end
						--end

						--for _,v in pairs(game.Workspace:GetChildren()) do
						--	if v.Name == "IRPARTr" and v.Transparency == 1 then
						--		if v:FindFirstChild("BillboardGui") then
						--			v.BillboardGui.Enabled = true
						--		end
						--		v.Material = Enum.Material.Neon
						--		v.Transparency = 0
						--	end

						--	if v:FindFirstChild("HelicopterIR") or v:FindFirstChild("Muzzle") then
						--		for _,v in pairs(v:GetDescendants()) do
						--			if v.Name == "IRPARTr" and v.Transparency == 1 then
						--				if v:FindFirstChild("BillboardGui") then
						--					v.BillboardGui.Enabled = true
						--				end
						--				v.Material = Enum.Material.Neon
						--				v.Transparency = 0
						--			end
						--		end
						--	end

						--	if v.Name == "K9" then
						--		for _,v in pairs(v:GetDescendants()) do
						--			if v.Name == "IRPARTr" and v.Transparency == 1 then
						--				if v:FindFirstChild("BillboardGui") then
						--					v.BillboardGui.Enabled = true
						--				end
						--				v.Material = Enum.Material.Neon
						--				v.Transparency = 0
						--			end
						--		end
						--	end
						--end

						--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
						--	if v.Name == "IRPARTv" and v.Material == Enum.Material.Plastic then
						--		v.Material = Enum.Material.Neon
						--	end
						--end

						--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
						--	if v.Name == "IRPARTr" and v.Transparency == 1 then
						--		if v:FindFirstChild("BillboardGui") then
						--			v.BillboardGui.Enabled = true
						--		end
						--		v.Material = Enum.Material.Neon
						--		v.Transparency = 0
						--	end
						--end
					end
				end)

				spawn(function()
					while nvgactive do
						task.wait(0.05)
						cycle(config.dark)
						cycle(config.light)
					end
				end)
				animating = false
			end)
		else
			playtween(offanim)
			delay(.5,function()
				playtween(off_overlayanim)
				--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
				--	if v:IsA("SurfaceLight") or v:IsA("SpotLight") or v:IsA("PointLight") then
				--		if v:FindFirstChild("IRYES") then
				--			v.Brightness = 0
				--			if v.Parent:FindFirstChild("BillboardGui") then
				--				v.Parent.BillboardGui.Enabled = false
				--			end
				--		end
				--	end
				--end

				--for _,v in pairs(game.Workspace:GetChildren()) do
				--	if v.Name == "IRPARTv" and v.Material == Enum.Material.Neon then
				--		v.Material = Enum.Material.Plastic
				--	end

				--	if v:FindFirstChild("Muzzle") then
				--		for _,g in pairs(v:GetDescendants()) do
				--			if g:IsA("SurfaceLight") or g:IsA("SpotLight") or g:IsA("PointLight") then
				--				if g:FindFirstChild("IRYES") then
				--					g.Brightness = 0
				--					if v.Parent:FindFirstChild("BillboardGui") then
				--						v.Parent.BillboardGui.Enabled = false
				--					end
				--				end
				--			end
				--		end
				--	end
				--end

				--for _,v in pairs(game.Workspace:GetChildren()) do
				--	if v.Name == "IRPARTr" and v.Transparency == 0 then
				--		if v:FindFirstChild("BillboardGui") then
				--			v.BillboardGui.Enabled = false
				--		end
				--		v.Material = Enum.Material.Plastic
				--		v.Transparency = 1
				--	end

				--	if v:FindFirstChild("HelicopterIR") or v:FindFirstChild("Muzzle") then
				--		for _,v in pairs(v:GetDescendants()) do
				--			if v.Name == "IRPARTr" and v.Transparency == 0 then
				--				if v:FindFirstChild("BillboardGui") then
				--					v.BillboardGui.Enabled = false
				--				end
				--				v.Material = Enum.Material.Plastic
				--				v.Transparency = 1
				--			end
				--		end
				--	end
				--end

				--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
				--	if v.Name == "IRPARTv" and v.Material == Enum.Material.Neon then
				--		v.Material = Enum.Material.Plastic
				--	end
				--end

				--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
				--	if v.Name == "IRPARTr" and v.Transparency == 0 then
				--		if v:FindFirstChild("BillboardGui") then
				--			v.BillboardGui.Enabled = false
				--		end
				--		v.Material = Enum.Material.Plastic
				--		v.Transparency = 1
				--	end
				--end
				animating = false
				if plr.PlayerGui:FindFirstChild("IR_GUI") then
					plr.PlayerGui.IR_GUI.TextButton.Visible = true
				end
			end)
		end
	end	
end


nvgevent.OnClientEvent:connect(function(nvg,activate)
	local twistjoint = nvg:WaitForChild("twistjoint")
	local config = require(nvg.AUTO_CONFIG)
	local lens = config.lens
	if lens then
		lens.Material = activate and "Neon" or "Glass"
	end

	if activate == true then
		task.delay(0.5,function()
			if nvg.Parent ~= nil then
				if nvg.Parent:FindFirstChild("Light1") then
					nvg.Parent.Light1.SpotLight.Enabled = true
				end
				if nvg.Parent:FindFirstChild("Light2") then
					nvg.Parent.Light2.SpotLight.Enabled = true
				end
			end
		end)
	else
		task.delay(0.3,function()
			if nvg.Parent ~= nil then
				if nvg.Parent:FindFirstChild("Light1") then
					nvg.Parent.Light1.SpotLight.Enabled = false
				end
				if nvg.Parent:FindFirstChild("Light2") then
					nvg.Parent.Light2.SpotLight.Enabled = false
				end
			end
		end)
	end

	playtween(config[activate and "onanim" or "offanim"])
end)

irevent.OnClientEvent:Connect(function(plr, mode)
	local LoopBreak = false
	spawn(function()
		while task.wait(.7) do
			if nvgactive and mode == true then
				local StrobePart = plr.Character.NODs["IR Strobe"].StrobePart
				StrobePart.PointLight.Enabled = true
				StrobePart.BillboardGui.Enabled = true
				task.wait(.1)
				local StrobePart = plr.Character.NODs["IR Strobe"].StrobePart
				StrobePart.PointLight.Enabled = false
				StrobePart.BillboardGui.Enabled = false

				StrobePart.Parent.IR:GetPropertyChangedSignal("Value"):Connect(function()
					if StrobePart.Parent.IR.Value == false then
						StrobePart.PointLight.Enabled = false
						StrobePart.BillboardGui.Enabled = false
						LoopBreak = true						
					end
				end)
				if LoopBreak == true then break end
			elseif mode == false then
				local StrobePart = plr.Character.NODs["IR Strobe"].StrobePart
				StrobePart.PointLight.Enabled = false
				StrobePart.BillboardGui.Enabled = false	
				break							
			end
		end
	end)
end)

local lighting = game.Lighting
local rs = game.ReplicatedStorage

local autolighting = rs:WaitForChild("EnableAutoLighting")

if autolighting.Value then

	function llerp(a,b,t)
		return a*(1-t)+b*t
	end

	local minbrightness = rs:WaitForChild("MinBrightness").Value
	local maxbrightness = rs:WaitForChild("MaxBrightness").Value
	local minambient = rs:WaitForChild("MinAmbient").Value
	local maxambient = rs:WaitForChild("MaxAmbient").Value
	local minoutdoor = rs:WaitForChild("MinOutdoorAmbient").Value
	local maxoutdoor = rs:WaitForChild("MaxOutdoorAmbient").Value

	function setdaytime()
		local newtime = lighting.ClockTime
		local middaydiff = math.abs(newtime-12)
		local f = (1-middaydiff/12)
		lighting.Brightness = llerp(minbrightness,maxbrightness,f)
		lighting.Ambient = minambient:lerp(maxambient,f)
		lighting.OutdoorAmbient = minoutdoor:lerp(maxoutdoor,f)
	end

	game:GetService("RunService").RenderStepped:connect(setdaytime)

end

UISConnection = UserInputService.InputBegan:Connect(function(input, gameprocessed)
	if nvgactive then 
		if input.KeyCode == Enum.KeyCode.Equals then
			if game.Lighting.ExposureCompensation <=5 then
				local A = game.Lighting.ExposureCompensation + 0.5
				tweenservice:Create(game.lighting, TweenInfo.new(0.2), {ExposureCompensation  = A }):Play() 
			end
		elseif input.KeyCode == Enum.KeyCode.Minus then
			if game.Lighting.ExposureCompensation >= 0.1 then
				local B = game.Lighting.ExposureCompensation - 0.5
				tweenservice:Create(game.lighting, TweenInfo.new(0.2), {ExposureCompensation  = B }):Play() 
			end
		end
	end
end)