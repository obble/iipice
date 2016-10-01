

    -- based on wardz' icicle tracker, WoD dev version (bootleg?)

    -- glacial spike:  ice lance no longer dumps icicles

    local aName, ns = ...

    -- *.*°.*°...*°.°*..*. CONFIG *..*..**.*
    local x, y = 19.2, 12    --   icon size
    -- ......***.*.*..°.*.*.***.*°.*.*°*.*

    local addon    = CreateFrame'Frame'
    local icicles  = {}
    local BACKDROP = {
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
        tiled  = false,
        insets = {left = -3, right = -3, top = -3, bottom = -3}
    }

    local spellcache = {
        [228597]  = true, --  [frostbolt]   :: this might need redefining for levels < 110
        [30455]   = true, --  [ice lance]
        [1000091] = true, --  [glacial spike]
    }

    local Print = function(...)
        print('|cff69CCF0Icicle Tracker:|r', ...)
    end

<<<<<<< HEAD
    local Parent = function()
        local f = C_NamePlate.GetNamePlateForUnit'player'
        if f then
            icicles[1]:SetPoint('BOTTOMLEFT', NamePlatePlayerResourceFrame, 'TOPLEFT', 0, 18)
        end
=======
    local Create = function()
    	--  local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(76613)
    	for i = 1, 6 do
    		local bu = CreateFrame('Frame', 'iipIcicle'..i, ice)
    		bu:SetFrameStrata'BACKGROUND'
    		bu:SetSize(size, size)
                bu:SetPoint('TOPLEFT', size, i*-(size))

    		bu.icon = bu:CreateTexture(nil, 'BACKGROUND')
    		bu.icon:SetTexture(icon)
    		bu.icon:SetAllPoints()

    		bu.t = bu:CreateFontString("txtIciclesDamage"..i, "GameFontNormal")
    		bu.t:SetFont(STANDARD_TEXT_FONT, 15)
    		bu.t:SetPoint('CENTER', bu, 'BOTTOM')
    		bu.t:SetText'0'

    		bu.cd = CreateFrame('Cooldown', nil, bu)
    		bu.cd:SetAllPoints()

    		icicles[i] = {}
    		icicles[i].basedamage = 0
    		icicles[i].timestamp  = 0
    		icicles[i].bu         = bu
    	end

    	icicles[6].bu:SetSize(size*2, size*2)
    	icicles[6].bu:SetPoint('TOPLEFT',0,6*-(size))
    	icicles[6].bu.t:SetPoint('TOPLEFT', (size*2)+(size/4), 0)
    	icicles[6].bu.t:SetFont(STANDARD_TEXT_FONT, 30)
>>>>>>> origin/master
    end


    function addon:Vars()
        _G[aName..'DB'] = setmetatable(_G[aName..'DB'] or {}, {__index = {
    		-- These values will be sent to DB if they don't exist. (__index)
    		yOfs      = 0,
    		xOfs      = 0,
    		point     = 'CENTER',
    		lock      = false,
    		scale     = 1.1,
    		textscale = 16,
    		combat    = true,
    	}})
    end

    function addon:SlashCMD(db)
        SLASH_IIPICE1 = '/icicle'
    	SlashCmdList.IIPICE = function(t)
    		local cmd, msg = t:match'^(%S*)%s*(.-)$'
    		if cmd == 'scale' then            -- SCALE
    			local v = tonumber(msg)
    			if v then
    				db.scale = v
    				icicles[1]:SetScale(v)
    				Print('scale set to '..v)
    			end
    		elseif cmd == 'combat' then       -- SHOW ONLY IN COMBAT
    			db.combat = not db.combat
    			self:RefreshFrames(db.combat)
    			Print'Setting saved.'
    		elseif cmd == 'lock' then         -- LOCK FRAME
    			db.lock = not db.lock
    			icicles[1]:EnableMouse(not db.lock)
    			Print'Setting saved.'
    		elseif cmd == 'textscale' then    -- FONT SIZE
    			local v = tonumber(msg)
    			if v then
    				db.textscale = value
    				icicles[5].t:SetPoint('CENTER', icicles[5], 0, -30 + db.textscale)
    				icicles[5].t:SetFont(STANDARD_TEXT_FONT, db.textscale, 'OUTLINE')
    			end
    		else
    			Print'Valid commands are:\n/icicle lock (Prevent frame mouse interactivity.)\n/icicle combat (Show frame only in combat.)\n/icicle scale 1.1 (Change frame size. Replace 1.1 with any number.)\n/icicle textscale 16 (Change damage font size. Replace 16 with any number.)'
    		end
    		-- TODO: Add option for grow anchor
        end
    end

    function addon:Create(db)
    	for i = 1, 5 do
    		local f = CreateFrame('Frame', aName..'icicle'..i, UIParent)
    		f:SetSize(x, y)
            f:SetBackdrop(BACKDROP)
    		f:SetBackdropColor(0, 0, 0, 1)
    		f:SetFrameStrata'LOW'
    		-- TODO: f.damage = 0
    		f.icicle = false

            f.icon = f:CreateTexture(nil, 'ARTWORK')
            f.icon:SetAllPoints()
            f.icon:SetColorTexture(.35, .45, .95)
            f.icon:SetAlpha(0)

            f.t = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
            f.t:SetPoint('BOTTOM', f, 'CENTER')
            f.t:SetFont(STANDARD_TEXT_FONT, db.textscale, 'OUTLINE')
            f.t:Hide()

    		if i > 1 then
    			f:SetPoint('LEFT', icicles[i - 1], 'RIGHT')
                if i == 5 then
    				f.overlay = CreateFrame('Frame', '$parentActivate', f, 'ActionBarButtonSpellActivationAlert')
    				f.overlay:SetSize((x + 1)*1.4, (y + 1)*1.4)       -- to-do: fix these weird ass calculations
    				f.overlay:SetPoint('TOPLEFT', f, -(x + 1)*.2, (y + 1)*.2)
    				f.overlay:SetPoint('BOTTOMRIGHT', f, (x + 1)*.2, -(y + 1)*.2)
    				f.overlay.animIn:HookScript('OnFinished', function(self)
    					self:Stop()
    					self:GetParent():Hide()
    				end)
    			end
    		end

    		icicles[i] = f
    	end
    	self:UpdateFrames()
    end

    -- Create expiration timer frame(s). (Every icicle have their own expiration time, so can't use only 1 timer)
    function addon:Timer(i)
    	if  icicles[i].timer then
    		-- Cancel active timer before refreshing expiration
    		icicles[i].timer:Cancel()
    	end
    	-- Start timer
    	icicles[i].timer = C_Timer.NewTimer(29, function(self) -- 29: Icicle expiration time
    		icicles[i].icicle = false
    		-- TODO: Decrease total dmg stored with the dmg stored in deactivated icicle frame
    		addon:UpdateFrames()
    		self = nil -- icFrame.timer = nil
    	end)
    end

    -- Update icicle count & dmg for frames
    function addon:UpdateFrames(startTimer)
    	local i = 1

    	-- I've reverted this whole function back to an old version by memory.
    	-- Stuff probably missing and needs changing.

    	while i <= 5 do
    		if icicles[i].icicle then -- If icicle exist
    			-- Enable icicle frame
    			icicles[i].icon:SetAlpha(1)
    			if startTimer then
    				--if not icicles[i].timer then
    					self:Timer(i)
    				--end
    			end
    		else
    			-- Deactivate
    			icicles[i].icon:SetAlpha(0)
    		end

    		if i == 5 then
    			-- TODO: Add update for stored damage count
    			-- See: AbbreviateLargeNumbers()
    			-- Play animation when full on icicles
    			if  icicles[i].icicle then
    				icicles[i].overlay:GetParent():Show()
    				icicles[i].overlay.animIn:Play()
    			end
    		end

    		i = i + 1
    	end
    end

    -- Hide/Show frames
    function addon:RefreshFrames(hide)
    	for i = 1, 5 do
    		if hide then
    			icicles[i].timer = nil -- stop timers
    			icicles[i]:Hide()

    			-- TODO: Reset dmg & icicle count
    		else
    			if not icicles[i]:IsVisible() then
    				icicles[i]:Show()
    			end
    		end
    	end
    end

    function addon:COMBAT_LOG_EVENT_UNFILTERED(_, _, etype, _, srcGUID, _, _, _, _, _, _, _, id, _, _, dmgAmount)
        if (not srcGUID )or srcGUID ~= self.player_GUID then return end   -- Spell not cast by player
        if (not spellcache[id]) then return end                               -- Wrong spell ID

    	--[[       -- TODO: check if this is still the case in legion

    	There's a bug with the counter when casting ice lance too fast after using frost bolt,
    	You can use this somehow to prevent it: (Can't remember where in CLEU to put it though)

    		local now = GetTime()
    		if (self.lastEvent and now - self.lastEvent) <= 0.9 then return end
    		self.lastEvent = now
    	]]

        if id == 30455 then print(id, etype) end

        if etype and ((id == 228597 and etype == 'SPELL_DAMAGE') or ((id == 30455 or id == 1000091) and etype == 'SPELL_CAST_SUCCESS')) then
        	-- increment
        	if  id == 228597 then
        		if icicles[5].icicle then  -- max amount reached
        			-- TODO: Remove dmg from oldest icicle
        			self:UpdateFrames(true)
        			return   -- stop func
        		end

        		for i = 1, 5 do
        			if not icicles[i].icicle then
        				icicles[i].icicle = true
        				break -- Stop loop
        			end
        		end

        		-- TODO: increment icicle damage count and text
        		-- dmgAmount/self.player_mastery*100 ?

        		self:UpdateFrames(true)
        		return
            -- decrement (icicle)
            elseif  id == 30455 or id == 1000091 then
        		if not icicles[1].icicle then return end -- do not decrement if no icicle exists
        		for i = 5, 1, -1 do -- reverse count
        			if  icicles[i].timer then
        				icicles[i].timer:Cancel()
        			end
        			icicles[i].icicle = false
        		end
        		self:UpdateFrames(true)
            end
    	end
    end

    function addon:PLAYER_REGEN_ENABLED()
    	if self:IsEventRegistered'COMBAT_LOG_EVENT_UNFILTERED' then
    		self:UnregisterEvent'COMBAT_LOG_EVENT_UNFILTERED' -- Unregister CLEU
    		if  _G[aName..'DB'].combat then
    			self:RefreshFrames(true) -- Hide frames
    		end
    	end
    end

    function addon:PLAYER_REGEN_DISABLED()
    	if not self:IsEventRegistered'COMBAT_LOG_EVENT_UNFILTERED' then
    		self:RegisterEvent'COMBAT_LOG_EVENT_UNFILTERED' -- Register CLEU
    		if  _G[aName..'DB'].combat then
    			self:RefreshFrames(false) -- Show frames
    		end
    	end
    end

    function addon:MASTERY_UPDATE()
    	self.player_mastery = GetMasteryEffect() -- / 100?
    end

    function addon:ACTIVE_TALENT_GROUP_CHANGED()
    	if GetSpecializationInfo(GetSpecialization() or 0) == 64 then
    		self:RegisterEvent'PLAYER_ENTERING_WORLD'
    		self:RegisterEvent'MASTERY_UPDATE'
    		self:PLAYER_ENTERING_WORLD()
    	else -- Not frost spec, disable
    		self:RefreshFrames(true)
    		self:UnregisterAllEvents()
            self:RegisterEvent'ACTIVE_TALENT_GROUP_CHANGED'
    	end
    end

    function addon:PLAYER_LEVEL_UP()
    	if UnitLevel'player' >= 80 then
    		-- Activate once lvl 80
    		self:PLAYER_LOGIN()
    		self:UnregisterEvent'PLAYER_LEVEL_UP'
    		self.PLAYER_LEVEL_UP = nil
    	end
    end

    function addon:PLAYER_ENTERING_WORLD()
        local _, class = UnitClass'player'

    	if class ~= 'MAGE' then
    		DisableAddOn(aName)
    		return
    	end

    	-- Check if player is lvl 80+
    	if UnitLevel'player' < 80 then
    		self:RegisterEvent'PLAYER_LEVEL_UP'
    		return
    	else
    		self.PLAYER_LEVEL_UP = nil -- Remove object from memory
    	end

    	-- SavedVariables
    	self:Vars()

    	local db         = _G[aName..'DB']
    	self.player_GUID = UnitGUID'player' -- Cache player unitGUID for CLEU
    	self.lastEvent   = nil

    	-- Slash Commands
    	self:SlashCMD(db)

    	-- Initialize
    	self:Create(db)
    	self:RegisterEvent'ACTIVE_TALENT_GROUP_CHANGED'
    	self:RegisterEvent'MASTERY_UPDATE'
        self:RegisterEvent'PLAYER_REGEN_DISABLED'
    	self:RegisterEvent'PLAYER_REGEN_ENABLED'
    	if _G[aName..'DB'].combat then
    		self:RefreshFrames(true)  -- Hide frames
    	else
    		self:RefreshFrames(false) -- Show frames
    	end

    	if  GetSpecializationInfo(GetSpecialization() or 0) ~= 64 then
    		self:ACTIVE_TALENT_GROUP_CHANGED() -- Disable addon if player is not frost specced
    	end

    	if (select(2, IsInInstance()) == 'arena') then
    		-- This event is sometimes not called when disconnecting in an arena,
    		-- make sure the function is always run.
    		self:PLAYER_ENTERING_WORLD()
    	end

    	-- Remove objects from memory
    	self.PLAYER_LOGIN = nil
    end

    addon:RegisterEvent'PLAYER_ENTERING_WORLD'
    addon:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

    hooksecurefunc(NamePlateDriverFrame, 'SetupClassNameplateBar', Parent)


    --
