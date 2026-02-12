-- Jump validation system to prevent client-side jump power hacking
-- Monitors player jumps and ensures their jump power matches purchased gravity coils

local Players = game:GetService("Players")

-- Function to validate a player's jump power against their purchased items
local function validatePlayerJumpPower(player)
	if not player then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	-- Get the player's authorized jump power from their data
	local authorizedJumpPower = player:GetAttribute("JumpPower") or 0

	-- Check if the humanoid's current jump power matches authorized amount
	local currentJumpPower = humanoid.JumpPower

	-- Also ensure UseJumpPower is set correctly (should always be true)
	if math.abs(currentJumpPower - authorizedJumpPower) > 0.1 or not humanoid.UseJumpPower then
		warn(
			string.format(
				"Jump power validation failed for %s: JumpPower Current=%.2f, Authorized=%.2f; UseJumpPower Current=%s. Resetting.",
				player.Name,
				currentJumpPower,
				authorizedJumpPower,
				tostring(humanoid.UseJumpPower)
			)
		)

		-- Reset to authorized values
		humanoid.UseJumpPower = true
		humanoid.JumpPower = authorizedJumpPower
	end
end

-- Function to handle humanoid state changes (detect jumping)
local function onHumanoidStateChanged(oldState, newState, player)
	-- Only validate when transitioning to jumping state
	if newState == Enum.HumanoidStateType.Jumping and oldState ~= Enum.HumanoidStateType.Jumping then
		validatePlayerJumpPower(player)
	end
end

-- Function to setup jump validation for a character
local function setupCharacterValidation(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	-- Connect to state changes to detect jumps
	humanoid.StateChanged:Connect(function(oldState, newState)
		onHumanoidStateChanged(oldState, newState, player)
	end)
end

-- Function to handle player joining
local function onPlayerAdded(player)
	-- Setup validation for current character if it exists
	local character = player.Character
	if character then
		setupCharacterValidation(player, character)
	end

	-- Setup validation for future characters
	player.CharacterAdded:Connect(function(c)
		setupCharacterValidation(player, c)
	end)
end

-- Initialize the jump validator
local function init()
	-- Connect to existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	-- Connect to new players
	Players.PlayerAdded:Connect(onPlayerAdded)
end

return {
	init = init,
	validatePlayerJumpPower = validatePlayerJumpPower,
}
