local ATTACHMENT_POINTS = {
	R15 = {
		Vest = "UpperTorso",
		Face = "Head",
		NODs = "Head",
		Belt = "LowerTorso",
	},
	R6 = {
		Vest = "Torso",
		Face = "Head",
		NODs = "Head",
		Belt = "Torso",
	}
}

local model = script.Parent.Parent:FindFirstChildOfClass("Model")

local upNVG = model:FindFirstChild("Up")
local downNVG = model:FindFirstChild("Down")
if upNVG and downNVG then
	local nvgjoint = Instance.new("Motor6D")
	nvgjoint.Part0 = model.Middle
	nvgjoint.Part1 = upNVG.PrimaryPart

	if upNVG:FindFirstChildOfClass("Model") and upNVG:FindFirstChildOfClass("Model"):FindFirstChild("Middle2") then
		local function createTubeJoint(side)
			local tube = upNVG[side.."Tube"]
			local joint = Instance.new("Motor6D")
			local upvalue = Instance.new("CFrameValue")
			local downvalue = Instance.new("CFrameValue")

			joint.Part0 = upNVG.PrimaryPart
			joint.Part1 = tube.Middle
			joint.Name = side:lower().."twistjoint"
			joint.C0 = upNVG.PrimaryPart.CFrame:inverse() * tube.Middle.CFrame
			joint.Parent = upNVG

			upvalue.Name = side:lower().."upvalue"
			upvalue.Value = joint.C0
			upvalue.Parent = upNVG

			downvalue.Name = side:lower().."downvalue"
			downvalue.Value = upNVG.PrimaryPart.CFrame:inverse() * tube.Middle2.CFrame
			downvalue.Parent = upNVG

			tube.Middle2:Destroy()
		end

		createTubeJoint("Left")
		createTubeJoint("Right")
	end

	local upvalue = Instance.new("CFrameValue")
	local downvalue = Instance.new("CFrameValue")

	upvalue.Name = "upvalue"
	downvalue.Name = "downvalue"

	upvalue.Value = model.Middle.CFrame:inverse()*upNVG.PrimaryPart.CFrame
	downvalue.Value = model.Middle.CFrame:inverse()*downNVG.PrimaryPart.CFrame

	upvalue.Parent = upNVG
	downvalue.Parent = upNVG

	nvgjoint.Name = "twistjoint"
	nvgjoint.C0 = upvalue.Value
	nvgjoint.Parent = upNVG

	downNVG:Destroy()

	-- Collect parts that need welding (more efficient than iterating during welding)
	local partsToWeld = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if (descendant:IsA("MeshPart") or descendant:IsA("Part") or descendant:IsA("UnionOperation"))
			and descendant.Name ~= "Middle" then
			partsToWeld[#partsToWeld + 1] = descendant
		end
	end

	-- Create welds for collected parts
	for _, part in ipairs(partsToWeld) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = part

		-- Find appropriate middle part to weld to
		local middlePart = part.Parent:FindFirstChild("Middle")
		if not middlePart and part.Parent.Parent then
			middlePart = part.Parent.Parent:FindFirstChild("Middle")
		end

		if middlePart then
			weld.Part1 = middlePart
			weld.Parent = part
		end
	end

	local autoconfig = script:WaitForChild("AUTO_CONFIG"):Clone()
	autoconfig.Parent = upNVG

elseif upNVG or downNVG then
	print("Missing "..(not upNVG and "Up" or "Down").." NVG Model")
end	

local attachmentType = model.Name

script.Parent.ClickDetector.MouseClick:Connect(function(p)
	if debounceActive then return end

	debounceActive = true
	delay(2, function()
		debounceActive = false
	end)
	local char = p.Character

	local oldmodel = char:FindFirstChild(attachmentType)
	if oldmodel then
		oldmodel:Remove()
	end

	local g = model:Clone()

	-- Unanchor all parts efficiently using ipairs
	for _, descendant in ipairs(g:GetDescendants()) do
		if descendant:IsA("MeshPart") or descendant:IsA("Part") or descendant:IsA("UnionOperation") then
			descendant.Anchored = false
		end
	end

	local weld = Instance.new("Weld")
	weld.Part0 = char[ATTACHMENT_POINTS[char.Humanoid.RigType.Name][attachmentType]]
	weld.Part1 = g.Middle
	weld.Parent = weld.Part0

	g.Parent = char

	local GUI = script.Parent["IR_GUI"]:Clone()
	GUI.Parent = game.Players:GetPlayerFromCharacter(char).PlayerGui
	GUI.Core.Disabled = false
end)