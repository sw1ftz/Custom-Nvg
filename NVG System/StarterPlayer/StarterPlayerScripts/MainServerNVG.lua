script.Parent = game.ServerScriptService
nvgevent = Instance.new("RemoteEvent")
nvgevent.Name = "nvg"
nvgevent.Parent = game.ReplicatedStorage

nvgremoveevent = Instance.new("RemoteEvent")
nvgremoveevent.Name = "removenvg"
nvgremoveevent.Parent = game.ReplicatedStorage

irevent = Instance.new("RemoteEvent")
irevent.Name = "ir"
irevent.Parent = game.ReplicatedStorage

local activenvgs = {}
local previoustoggle = {}

nvgevent.OnServerEvent:Connect(function(plr, active)
	if plr.Character then
		local helmet = plr.Character:FindFirstChild("NODs")
		if helmet then
			local nvg = helmet:FindFirstChild("Up")
			if nvg then
				local id = plr.Name
				local prevtoggle = previoustoggle[id]
				local newt = time()
				if not prevtoggle or newt-prevtoggle > .6 then
					previoustoggle[id] = newt
					local bool
					--if activenvgs[id] then
					--	activenvgs[id] = nil
					--	bool = false
					--else
					--	activenvgs[id] = nvg
					--	bool = true
					--end
					for _,v in pairs(game.Players:GetChildren())do
						if v ~= plr and v:IsA("Player") then
							nvgevent:FireClient(v,nvg,active)
						end
					end
				end	
			end
		end
	end	
end)

nvgremoveevent.OnServerEvent:Connect(function(plr, helmet)
	if helmet ~= nil then
		helmet:Destroy()
	end
end)

irevent.OnServerEvent:Connect(function(plr, mode)
	if plr.Character:FindFirstChild("NODs") then
		if plr.Character.NODs:FindFirstChild("IR Strobe") then
			plr.Character.NODs:FindFirstChild("IR Strobe").IR.Value = mode
			irevent:FireAllClients(plr, mode)
		end
	end
end)


local enabledautolighting = script:WaitForChild("EnableAutoLighting")

if enabledautolighting.Value then
	
	local lighting = game.Lighting
	local secs = lighting.ClockTime*3600
	local speed = script:WaitForChild("TimeSpeed").Value

	game:GetService("RunService").Heartbeat:Connect(function(dt)
		secs = secs+dt*speed
		if secs >= 86400 then --seconds in a day
			secs = secs-86400
		end
		lighting.ClockTime = secs/3600
	end)

end

for _,v in pairs(script:GetChildren())do
	if string.match(v.ClassName,"Value") then
		v.Parent = game.ReplicatedStorage
	end
end


game.Players.PlayerAdded:Connect(function(plr)
	for _,nvg in pairs(activenvgs) do
		if nvg then
			nvgevent:FireClient(plr,nvg,true)
		end
	end
end)


--for _,v in pairs(game.Workspace.Players:GetDescendants()) do
--	if v:IsA("SurfaceLight") or v:IsA("SpotLight") or v:IsA("PointLight") then
--		if v:FindFirstChild("IRYES") then
--			v.BrightnessVal.Value = v.Brightness
--			v.Brightness = 0
--		end
--	end
--end

--game.Workspace.ChildAdded:Connect(function()
--	for _,v in pairs(game.Workspace:GetChildren()) do
--		if v:FindFirstChild("Muzzle") then
--			for _,g in pairs(v:GetDescendants()) do
--				if g:IsA("SurfaceLight") or g:IsA("SpotLight") or g:IsA("PointLight") then
--					if g:FindFirstChild("IRYES") then
--						g.BrightnessVal.Value = g.Brightness
--						g.Brightness = 0
--					end
--				end
--			end
--		end
--	end
--end)