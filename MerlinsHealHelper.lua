merlinsHealHelper = {}

merlinsHealHelper.replacable = false
merlinsHealHelper.LAM2 = LibStub("LibAddonMenu-2.0")

merlinsHealHelper.name = "MerlinsHealHelper"
merlinsHealHelper.version = "1.0.5"
merlinsHealHelper.unitTags = {}
merlinsHealHelper.inCombat = false
merlinsHealHelper.playerName = ""
merlinsHealHelper.LOW_HEALTH = 0.65

-- Initialize our addon
function merlinsHealHelper.OnAddOnLoaded(eventCode, addOnName)
	if (addOnName == merlinsHealHelper.name) then
		merlinsHealHelper:Initialize()
		merlinsHealHelper:CreateSettingsMenu()
	end
end

function merlinsHealHelper.CreateSettingsMenu()
	local colorYellow = "|cFFFF22"
	local panelData = {
		type = "panel",
		name = "Merlins Heal Helper",
		displayName = colorYellow.."Merlin's|r Heal Helper",
		author = "@Just_Merlin",
		version = merlinsHealHelper.version,
		slashCommand = "/merlinsHealHelper",
		registerForRefresh = true,
		registerForDefaults = true,
	}
	local cntrlOptionsPanel = merlinsHealHelper.LAM2:RegisterAddonPanel("merlinsHealHelper_Options", panelData)
	local optionsData = {
		[1] = {
			type = "description",
			text = colorYellow.."Merlin's|r Heal Helper",
		},
		[2] = {
			type = "slider",
			name =  GetString(LOCALES_HEALTH_ALERT),
			tooltip = GetString(LOCALES_HEALTH_ALERT_TP),
			min = 5,
			max = 100,
			step = 5,
			default = 65,
			getFunc = function() return merlinsHealHelper.savedVariables.userLOW_HEALTH end,
			setFunc = function(iValue)
									PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_JOINED)
									merlinsHealHelper.savedVariables.userLOW_HEALTH = iValue
									merlinsHealHelper.CheckLOW_HEALTH(false)
								end,
		},
		[3] = {
			type = "checkbox",
			name = GetString(LOCALES_ENABLE_REPOSITION),
			tooltip = GetString(LOCALES_ENABLE_REPOSITION_TP),
			default = false,
			getFunc = function() return merlinsHealHelper.savedVariables.userVISIBLE end,
			setFunc = function(bValue)
									PlaySound(SOUNDS.VOICE_CHAT_MENU_CHANNEL_JOINED)
									merlinsHealHelper.savedVariables.userVISIBLE = bValue
									merlinsHealHelper.ShowInterface()
								end
		},
	}
	merlinsHealHelper.LAM2:RegisterOptionControls("merlinsHealHelper_Options", optionsData)
end

local function OnPluginLoaded(event, addon)
end

--integer eventCode, string unitTag, integer powerIndex, integer powerType, integer powerValue, integer powerMax, integer powerEffectiveMax
function merlinsHealHelper.OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	merlinsHealHelper.UpdateVolatileUnitInfo(unitTag)
end

function merlinsHealHelper:Initialize()
	self.inCombat = IsUnitInCombat("player")
	self.playerName = GetUnitName("player")
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_POWER_UPDATE, merlinsHealHelper.OnPowerUpdate)
	self.savedVariables = ZO_SavedVars:NewAccountWide("MerlinsHealHelperSavedVariables", 1, nil, {})
	self:RestorePosition()
	self:CheckLOW_HEALTH(true)

	merlinsHealHelperIndicatorBG:SetAlpha(0)
	merlinsHealHelperIndicator:SetWidth(600)
	merlinsHealHelperIndicator:SetHeight(50)

	merlinsHealHelperIndicatorT:ClearAnchors()
	merlinsHealHelperIndicatorT:SetAnchor(CENTER, merlinsHealHelperIndicator, CENTER, 0, 0)

	merlinsHealHelperIndicatorT:SetWidth(600)
	merlinsHealHelperIndicatorT:SetHeight(50)
	merlinsHealHelperIndicatorT:SetHorizontalAlignment(1)

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GAME_CAMERA_UI_MODE_CHANGED, merlinsHealHelper.UIModeChanged)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, merlinsHealHelper.LateInitialize)
	
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
	
	EVENT_MANAGER:RegisterForEvent(self.name,  EVENT_ACTION_LAYER_POPPED , merlinsHealHelper.ShowInterface)
	EVENT_MANAGER:RegisterForEvent(self.name,  EVENT_ACTION_LAYER_PUSHED , merlinsHealHelper.HideInterface)
end

-- Fancy loaded message
function merlinsHealHelper.LateInitialize(eventCode, addOnName)
	 --d("Merlin's Heal Helper loaded...")
	EVENT_MANAGER:UnregisterForEvent(merlinsHealHelper.name, EVENT_PLAYER_ACTIVATED);
end


function merlinsHealHelper.OnPlayerCombatState(event, inCombat)
	-- The ~= operator is "not equal to" in Lua.
	if inCombat ~= merlinsHealHelper.inCombat then
		-- The player's state has changed. Update the stored state...
		merlinsHealHelper.inCombat = inCombat
		if inCombat then
			-- entering combat - clear unitTags
			merlinsHealHelper.unitTags = {}
		else
			-- exiting combat - clear indicator
			merlinsHealHelperIndicatorT:SetColor(255, 255, 255, 255)
			merlinsHealHelperIndicatorT:SetText("")
		end
	end
end

function merlinsHealHelper.UpdateIndicator()
	local priorityUnit = nil;
	local outOfRangeUnit = nil;
	if merlinsHealHelper.inCombat then
		for i, unit in pairs(merlinsHealHelper.unitTags) do
			if unit.Online and (not unit.Dead) and unit.LowHealth then
				if unit.InSupportRange then
					if not priorityUnit then
						priorityUnit = unit
					else
						if unit.HealthPercent < priorityUnit.HealthPercent then
							priorityUnit = unit
						end
					end
				else
					if not outOfRangeUnit then
						outOfRangeUnit = unit
					else
						if unit.HealthPercent < outOfRangeUnit.HealthPercent then
							outOfRangeUnit = unit
						end
					end
				end
			end
		end
		
		-- should have out of range units equal priority? 
		if TBDTBDTBDTBD and outOfRangeUnit.HealthPercent < priorityUnit.HealthPercent then
			priorityUnit = outOfRangeUnit
		end

		if priorityUnit then
			if priorityUnit.InSupportRange then
				merlinsHealHelperIndicatorT:SetColor(255, 0, 0, 255)
				if merlinsHealHelper.playerName == priorityUnit.Name then
					merlinsHealHelperIndicatorT:SetText(GetString(LOCALES_HEAL_YOURSELF))
				else
					merlinsHealHelperIndicatorT:SetText(GetString(LOCALES_HEAL).." " .. priorityUnit.Name .. "!")
				end
			else
				merlinsHealHelperIndicatorT:SetColor(255, 255, 0, 255)
				merlinsHealHelperIndicatorT:SetText(priorityUnit.Name .. " "..GetString(LOCALES_OUT_OF_RANGE))
			end
		else
			merlinsHealHelperIndicatorT:SetText("")
		end

	end
end

function merlinsHealHelper.UpdateVolatileUnitInfo(unitTag)
	if not unitTag then
		return
	end
	
	local currentHp, maxHp, effectiveMaxHp
	local unit = {}

	if merlinsHealHelper.inCombat and (string.sub(unitTag,1,string.len("group"))=="group" or string.sub(unitTag,1,string.len("player"))=="player") then
		currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)

		unit.Name = GetUnitName(unitTag)
		unit.Dead = IsUnitDead(unitTag)
		unit.Online = IsUnitOnline(unitTag)
		unit.HealthPercent = currentHp / maxHp
		unit.LowHealth = unit.HealthPercent <= merlinsHealHelper.LOW_HEALTH
		unit.InSupportRange = IsUnitInGroupSupportRange(unitTag)
		unit.UnitTag = unitTag

		merlinsHealHelper.unitTags[unitTag] = unit
		merlinsHealHelper.UpdateIndicator()
	end
end

function merlinsHealHelper:CheckLOW_HEALTH(isSelf)
	local userValue = 0;

	if isSelf then
		userValue = self.savedVariables.userLOW_HEALTH
	else
		userValue = merlinsHealHelper.savedVariables.userLOW_HEALTH
	end

	if (userValue and userValue > 5) then
		if isSelf then
			self.LOW_HEALTH = (userValue/100)
		else
			merlinsHealHelper.LOW_HEALTH = (userValue/100)
		end
	end
end

function merlinsHealHelper.OnIndicatorMoveStop()
	merlinsHealHelper.savedVariables.left = merlinsHealHelperIndicator:GetLeft()
	merlinsHealHelper.savedVariables.top = merlinsHealHelperIndicator:GetTop()
end

function merlinsHealHelper:RestorePosition()
	local left = self.savedVariables.left
	local top = self.savedVariables.top

	merlinsHealHelperIndicator:ClearAnchors()
	merlinsHealHelperIndicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

function merlinsHealHelper.UIModeChanged()
	if (IsReticleHidden()) then
		merlinsHealHelperIndicatorBG:SetAlpha(100)
		merlinsHealHelperIndicatorT:SetText("Merlin's Heal Helper")
	else
		merlinsHealHelperIndicatorBG:SetAlpha(0)
		merlinsHealHelperIndicatorT:SetText("")
	end
end

-- Hide or show the add-on when other panels are open, like inventory.
-- There's probably a better way to hook this into the screne manager.
function merlinsHealHelper.HideInterface(eventCode,layerIndex,activeLayerIndex)
	if (merlinsHealHelper.savedVariables.userVISIBLE ~= true) then
		merlinsHealHelperIndicator:SetHidden(true)
	end
end

function merlinsHealHelper.ShowInterface(...)
    merlinsHealHelperIndicator:SetHidden(false)
	if (ZO_ReticleContainer:IsHidden() == true and merlinsHealHelper.savedVariables.userVISIBLE ~= true) then
		merlinsHealHelperIndicator:SetHidden(true)
	end
end

EVENT_MANAGER:RegisterForEvent(merlinsHealHelper.name, EVENT_ADD_ON_LOADED, merlinsHealHelper.OnAddOnLoaded);
