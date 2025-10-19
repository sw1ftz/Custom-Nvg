wait()

if script.Parent.Parent.Parent.Name == "PlayerGui" then
	local player = script.Parent.Parent.Parent.Parent
	local helmet = player.Character.NODs.Up
	local nods = player.Character.NODs
	local fakeMountNames = { Mount1_Fake = true, Mount2_Fake = true }
	local originalTransparency = {}

	local function setNVGLightsEnabled(enabled)
		for _, d in pairs(helmet:GetDescendants()) do
			if d:IsA("SpotLight") or d:IsA("PointLight") or d:IsA("SurfaceLight") then
				d.Enabled = enabled
			end
		end
	end

	local function captureLightPartTransparencies()
		for _, d in pairs(helmet:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Decal")) and originalTransparency[d] == nil then
				originalTransparency[d] = d.Transparency
			end
		end
		-- Also capture fake mount parts that may live outside the helmet under NODs
		for _, d in pairs(nods:GetDescendants()) do
			if d:IsA("BasePart") and fakeMountNames[d.Name] and originalTransparency[d] == nil then
				originalTransparency[d] = d.Transparency
			end
		end
	end

	local function setLightPartsVisibility(isMounted)
		for part, saved in pairs(originalTransparency) do
			if part and part.Parent then
				if fakeMountNames[part.Name] then
					-- Fake mount parts: visible when NOT mounted, invisible when mounted
					part.Transparency = isMounted and 1 or 0
				else
					part.Transparency = isMounted and saved or 1
				end
			end
		end
	end

	local function updateHelmetVisibility(isMounted)
		setNVGLightsEnabled(isMounted)
		setLightPartsVisibility(isMounted)
	end

	local function onClick(mouse)
		local isMounted = helmet.Mounted.Value
		helmet.Mounted.Value = not isMounted
		updateHelmetVisibility(not isMounted)
		end
	end

	script.Parent.MouseButton1Down:Connect(onClick)

	-- Capture target parts' original transparency and sync initial state
	captureLightPartTransparencies()
	-- Sync initial visual and light state with current mounted value
	updateHelmetVisibility(helmet.Mounted.Value)
end