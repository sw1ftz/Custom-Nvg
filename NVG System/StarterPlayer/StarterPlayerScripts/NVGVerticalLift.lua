-- NVG Vertical Lift System Module
-- Handles vertical rotation of NVG around Middle part

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- NVG Vertical Lift System
local VerticalLift = {}
VerticalLift.__index = VerticalLift

-- Default settings
local DEFAULT_SETTINGS = {
    rotationSpeed = 2, -- Degrees per adjustment
    minAngle = -45, -- Minimum rotation (down)
    maxAngle = 45, -- Maximum rotation (up)
}

function VerticalLift.new(helmet, gui)
    local self = setmetatable({}, VerticalLift)
    
    -- Initialize properties
    self.currentAngle = 0
    self.minAngle = DEFAULT_SETTINGS.minAngle
    self.maxAngle = DEFAULT_SETTINGS.maxAngle
    self.rotationSpeed = DEFAULT_SETTINGS.rotationSpeed
    self.isAdjusting = false
    self.enabled = true -- allow adjustment only when NVG is OFF
    
    -- References
    self.helmet = helmet
    self.gui = gui
    self.middlePart = nil
    self.nvgPart = nil
    self.twistJoint = nil
    self.originalC0 = nil
    self.upValue = nil
    self.downValue = nil
    
    -- Connections
    self.connections = {}
    
    -- Initialize the system
    self:Initialize()
    
    return self
end

function VerticalLift:Initialize()
    print("Initializing Vertical Lift System...")
    
    if not self.helmet then 
        warn("NVG Vertical Lift: No helmet provided")
        return false 
    end
    
    -- Get required parts
    self.middlePart = self.helmet:FindFirstChild("Middle")
    self.nvgPart = self.helmet:FindFirstChild("Up")
    
    print("Middle part found:", self.middlePart ~= nil)
    print("NVG part found:", self.nvgPart ~= nil)
    
    if not self.middlePart or not self.nvgPart then
        warn("NVG Vertical Lift: Missing required parts (Middle or Up)")
        return false
    end

    -- The 'Up' object is a Model; use its Motor6D 'twistjoint' to rotate
    self.twistJoint = self.nvgPart:FindFirstChild("twistjoint")
    if not self.twistJoint or not self.twistJoint:IsA("Motor6D") then
        warn("NVG Vertical Lift: Missing Motor6D 'twistjoint' inside Up model")
        return false
    end
    
    -- Get CFrameValues
    self.upValue = self.nvgPart:FindFirstChild("upvalue")
    self.downValue = self.nvgPart:FindFirstChild("downvalue")
    
    print("UpValue found:", self.upValue ~= nil)
    print("DownValue found:", self.downValue ~= nil)
    
    -- Calculate angles from CFrameValues
    if self.upValue and self.downValue then
        self:CalculateAnglesFromCFrameValues()
        print("Using CFrameValues for angles")
    else
        warn("NVG Vertical Lift: Missing CFrameValues (upvalue or downvalue), using defaults")
        self:SetDefaultAngles()
    end
    
    print("Angle range:", self.minAngle, "to", self.maxAngle)
    
    -- Create HUD elements
    self:CreateHUD()
    print("HUD created")
    
    -- Set up input handling
    self:SetupInputHandling()
    print("Input handling set up")
    
    -- Initialize position and indicator once
    self:UpdatePosition()
    self:UpdateIndicator()
    
    print("Vertical Lift System initialization complete")
    return true
end

function VerticalLift:CalculateAnglesFromCFrameValues()
    local upCFrame = self.upValue.Value
    local downCFrame = self.downValue.Value
    
    -- Extract rotation angles from the CFrames (returns X, Y, Z values)
    local upX = upCFrame:ToEulerAnglesXYZ()
    local downX = downCFrame:ToEulerAnglesXYZ()
    
    -- Convert to degrees and set limits (only X rotation matters for vertical lift)
    self.maxAngle = math.deg(upX)
    self.minAngle = math.deg(downX)
    
    -- Store original joint configuration (neutral position)
    self.originalC0 = self.twistJoint.C0
end

function VerticalLift:SetDefaultAngles()
    self.maxAngle = DEFAULT_SETTINGS.maxAngle
    self.minAngle = DEFAULT_SETTINGS.minAngle
    self.originalC0 = self.twistJoint.C0
end

function VerticalLift:CreateHUD()
    print("CreateHUD called - GUI exists:", self.gui ~= nil)
    
    if not self.gui then 
        warn("No GUI provided for HUD creation")
        return 
    end
    
    print("GUI parent:", self.gui.Parent)
    
    -- Create vertical lift indicator
    local verticalLiftIndicator = Instance.new("TextLabel")
    verticalLiftIndicator.Name = "VerticalLiftIndicator"
    verticalLiftIndicator.Text = "Vertical: 0°"
    verticalLiftIndicator.Size = UDim2.new(0.12, 0, 0.03, 0)
    verticalLiftIndicator.Position = UDim2.new(0.02, 0, 0.15, 0)
    verticalLiftIndicator.BackgroundTransparency = 0.3
    verticalLiftIndicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    verticalLiftIndicator.TextColor3 = Color3.fromRGB(0, 255, 0)
    verticalLiftIndicator.Font = Enum.Font.SourceSansBold
    verticalLiftIndicator.TextScaled = true
    verticalLiftIndicator.BorderSizePixel = 0
    verticalLiftIndicator.Parent = self.gui
    
    print("Vertical lift indicator created and parented")
    
    -- Create vertical lift instructions
    local verticalLiftInstructions = Instance.new("TextLabel")
    verticalLiftInstructions.Name = "VerticalLiftInstructions"
    verticalLiftInstructions.Text = "↑↓ Vertical | 2 Max Up | 3 Max Down"
    verticalLiftInstructions.Size = UDim2.new(0.3, 0, 0.025, 0)
    verticalLiftInstructions.Position = UDim2.new(0.02, 0, 0.18, 0)
    verticalLiftInstructions.BackgroundTransparency = 1
    verticalLiftInstructions.TextColor3 = Color3.fromRGB(150, 150, 150)
    verticalLiftInstructions.Font = Enum.Font.SourceSans
    verticalLiftInstructions.TextScaled = true
    verticalLiftInstructions.Parent = self.gui
    
    print("Vertical lift instructions created and parented")
    print("HUD creation complete")
end

function VerticalLift:SetEnabled(enabled)
    self.enabled = enabled and true or false
end

function VerticalLift:SetupInputHandling()
    local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not self.enabled then return end
        
        print("Input received:", input.KeyCode.Name)
        
        if input.KeyCode == Enum.KeyCode.Up then
            -- Raise NVG vertically
            print("Up arrow pressed - raising NVG")
            self:AdjustLift(1)
        elseif input.KeyCode == Enum.KeyCode.Down then
            -- Lower NVG vertically
            print("Down arrow pressed - lowering NVG")
            self:AdjustLift(-1)
        elseif input.KeyCode == Enum.KeyCode.Two then
            -- Set vertical lift to maximum up
            print("2 key pressed - setting to max up")
            self:SetAngle(self.maxAngle)
        elseif input.KeyCode == Enum.KeyCode.Three then
            -- Set vertical lift to maximum down
            print("3 key pressed - setting to max down")
            self:SetAngle(self.minAngle)
        end
    end)
    
    table.insert(self.connections, connection)
    print("Input connection created")
end

function VerticalLift:AdjustLift(direction)
    print("AdjustLift called with direction:", direction)
    
    if not self.enabled or not self.middlePart or not self.nvgPart or self.isAdjusting then 
        print("AdjustLift blocked - middlePart:", self.middlePart ~= nil, "nvgPart:", self.nvgPart ~= nil, "isAdjusting:", self.isAdjusting)
        return 
    end
    
    self.isAdjusting = true
    
    local targetAngle = self.currentAngle + (direction * self.rotationSpeed)
    targetAngle = math.max(self.minAngle, math.min(self.maxAngle, targetAngle))
    
    print("Current angle:", self.currentAngle, "Target angle:", targetAngle)
    
    if targetAngle ~= self.currentAngle then
        self.currentAngle = targetAngle
        self:UpdatePosition()
        self:UpdateIndicator()
        
        print("Angle updated to:", self.currentAngle)
    end
    
    self.isAdjusting = false
end

function VerticalLift:SetAngle(angle)
    if not self.enabled or not self.middlePart or not self.nvgPart or self.isAdjusting then return end
    
    self.isAdjusting = true
    self.currentAngle = math.max(self.minAngle, math.min(self.maxAngle, angle))
    self:UpdatePosition()
    self:UpdateIndicator()
    
    self.isAdjusting = false
end

function VerticalLift:UpdatePosition()
    if not self.twistJoint then return end
    
    -- Use CFrameValues if available, otherwise use calculated rotation
    if self.upValue and self.downValue then
        -- Interpolate between upvalue and downvalue based on current angle
        local normalizedAngle = (self.currentAngle - self.minAngle) / (self.maxAngle - self.minAngle)
        normalizedAngle = math.max(0, math.min(1, normalizedAngle)) -- Clamp between 0 and 1
        
        -- Lerp between downvalue and upvalue to produce target C0 for the joint
        local targetC0 = self.downValue.Value:Lerp(self.upValue.Value, normalizedAngle)
        
        -- Apply to the Motor6D
        self.twistJoint.C0 = targetC0
    else
        -- Fallback to calculated rotation if CFrameValues not available
        if self.originalC0 then
            local rotationCFrame = CFrame.Angles(math.rad(self.currentAngle), 0, 0)
            self.twistJoint.C0 = self.originalC0 * rotationCFrame
        end
    end
end

function VerticalLift:UpdateIndicator()
    if self.gui and self.gui:FindFirstChild("VerticalLiftIndicator") then
        self.gui.VerticalLiftIndicator.Text = "Vertical: " .. math.floor(self.currentAngle) .. "°"
    end
end

-- Compute target C0 for a given logical angle (degrees)
function VerticalLift:computeTargetC0(angle)
    if not self.twistJoint then return nil end
    local clamped = math.max(self.minAngle, math.min(self.maxAngle, angle))
    if self.upValue and self.downValue then
        local normalized = (clamped - self.minAngle) / (self.maxAngle - self.minAngle)
        normalized = math.max(0, math.min(1, normalized))
        return self.downValue.Value:Lerp(self.upValue.Value, normalized)
    elseif self.originalC0 then
        return self.originalC0 * CFrame.Angles(math.rad(clamped), 0, 0)
    end
    return nil
end

-- Programmatic setter that ignores enabled gating and applies instantly
function VerticalLift:ForceSetAngle(angle)
    if not self.twistJoint then return end
    local targetC0 = self:computeTargetC0(angle)
    if not targetC0 then return end
    self.currentAngle = math.max(self.minAngle, math.min(self.maxAngle, angle))
    self.twistJoint.C0 = targetC0
    self:UpdateIndicator()
end

-- Tween to a given angle over duration seconds (ignores enabled gating)
function VerticalLift:ForceTweenToAngle(angle, duration)
    if not self.twistJoint then return end
    local targetC0 = self:computeTargetC0(angle)
    if not targetC0 then return end
    local info = TweenInfo.new(duration or 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local tween = TweenService:Create(self.twistJoint, info, { C0 = targetC0 })
    local connection
    connection = tween.Completed:Connect(function()
        self.currentAngle = math.max(self.minAngle, math.min(self.maxAngle, angle))
        self:UpdateIndicator()
        if connection then connection:Disconnect() end
    end)
    table.insert(self.connections, connection)
    tween:Play()
end

function VerticalLift:GetCurrentAngle()
    return self.currentAngle
end

function VerticalLift:GetAngleRange()
    return self.minAngle, self.maxAngle
end

function VerticalLift:SetRotationSpeed(speed)
    self.rotationSpeed = speed
end

function VerticalLift:Destroy()
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Clear references
    self.connections = {}
    self.helmet = nil
    self.gui = nil
    self.middlePart = nil
    self.nvgPart = nil
    self.twistJoint = nil
    self.originalC0 = nil
    self.upValue = nil
    self.downValue = nil
end

return VerticalLift
