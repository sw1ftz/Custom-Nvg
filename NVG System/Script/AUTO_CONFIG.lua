local tweenservice = game:GetService("TweenService")

-- Pre-cache references to avoid repeated WaitForChild calls
local parent = script.Parent
local twistjoint = parent:WaitForChild("twistjoint")
local lens = parent:WaitForChild("Lens", 0.5)
local downvalue = parent:WaitForChild("downvalue")
local upvalue = parent:WaitForChild("upvalue")
local nvgSettings = parent:WaitForChild("NVG_Settings")

-- Set lens color
lens.Color = nvgSettings.LensColor.Value

-- Tween configuration
local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local onanim = {
	0.5,
	tweenservice:Create(twistjoint, info, {C0 = downvalue.Value}),
	0.5,
}

local offanim = {
	0.5,
	tweenservice:Create(twistjoint, info, {C0 = upvalue.Value}),
	0.5,
}

-- Shared src array for both dark and light modes
local sharedSrc = {
	13805177336,
	13805178177,
	13805179202,
	13805180082,
	13805180883,
	13805181794
}

local config = {
	dark = {src = sharedSrc},
	light = {src = sharedSrc},
	onanim = onanim,
	offanim = offanim,
	tweeninfo = info,
	lens = lens,
	verticalLiftSettings = {
		minAngle = -45, -- Minimum rotation angle (down)
		maxAngle = 45, -- Maximum rotation angle (up)
		rotationSpeed = 2, -- Degrees per adjustment
		rotationAxis = "X" -- Rotation axis (X for pitch)
	}
}

return config
