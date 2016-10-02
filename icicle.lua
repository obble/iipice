

    -- based on wardz' icicle tracker, WoD dev version (bootleg?)

    -- glacial spike:  ice lance no longer dumps icicles

    local aName, ns = ...

    -- *.*°.*°...*°.°*..*. CONFIG *..*..**.*
    local x, y             = 40, 40    --   icon size
    local xoffset, yoffset = 3,  0     --   spacing between button
    -- ......***.*.*..°.*.*.***.*°.*.*°*.*

    local icicles  = {}
    local BACKDROP = {
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
        tiled  = false,
        insets = {left = -3, right = -3, top = -3, bottom = -3}
    }

    -- lets also use our handler as a container
    local addon = CreateFrame('Frame', nil, UIParent)
    addon:SetSize((x*5)+(xoffset*5), y+(yoffset*5))

    local spellcache = {
        [228597]  = true, --  [frostbolt]   :: this might need redefining for levels < 110
        [30455]   = true, --  [ice lance]
        [199786] = true, --  [glacial spike]
    }

    local Print = function(...)
        print('|cff69CCF0Icicle Tracker:|r', ...)
    end

    local Parent = function()
        local f = C_NamePlate.GetNamePlateForUnit'player'
        addon:ClearAllPoints()
        if f and _G[aName..'DB'].nameplate then
            addon:SetPoint('BOTTOMLEFT', NamePlatePlayerResourceFrame, 'TOPLEFT', -(x*5)/4, 18)
        else
            addon:SetPoint('CENTER', UIParent, 0, 120)
        end
    end

    local siValue = function(v)
        if not v then return '' end
        local absvalue = abs(v)
        local str, val
        if  absvalue >= 1e7 then
            str, val = '%.1fm', v/1e6
        elseif absvalue >= 1e6 then
            str, val = '%.2fm', v/1e6
        elseif absvalue >= 1e5 then
            str, val = '%.0fk', v/1e3
        elseif absvalue >= 1e3 then
            str, val = '%.1fk', v/1e3
        else
            str, val = '%d', v
        end
        return format(str, val)
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
    		combat    = false,
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
    		local f = CreateFrame('Frame', aName..'icicle'..i, self)
    		f:SetSize(x, y)
            f:SetBackdrop(BACKDROP)
    		f:SetBackdropColor(0, 0, 0, 1)
    		f:SetFrameStrata'LOW'
    		f.base   = 0
    		f.icicle = false

            f.icon = f:CreateTexture(nil, 'ARTWORK')
            f.icon:SetAllPoints()
            f.icon:SetColorTexture(.35, .45, .95)
            f.icon:SetAlpha(0)

            f.t = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
            f.t:SetPoint'CENTER'
            f.t:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
            f.t:SetShadowOffset(0, 0)
            f.t:Hide()

    		if i > 1 then
    			f:SetPoint('LEFT', icicles[i - 1], 'RIGHT', xoffset, yoffset)
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
            else
                f:SetPoint'LEFT'
    		end

    		icicles[i] = f
    	end

        local total = CreateFrame('Frame', aName..'icetotal', self)
        total:SetSize(x + 30, y)
        total:SetPoint('LEFT', icicles[5], 'RIGHT')

        total.t = total:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
        total.t:SetAllPoints()
        total.t:SetShadowOffset(0, 0)

        local tooltip = CreateFrame('GameTooltip', 'iipGSTooltip', UIParent, 'GameTooltipTemplate')
        tooltip:SetOwner(UIParent, 'ANCHOR_NONE')

    	self:UpdateFrames()
    end

    -- create expiration timer frame(s). (Every icicle have their own expiration time, so can't use only 1 timer)
    function addon:Timer(i)
    	if  icicles[i].timer then
    		-- cancel active timer before refreshing expiration
    		icicles[i].timer:Cancel()
    	end
    	-- Start timer
    	icicles[i].timer = C_Timer.NewTimer(29, function(self) -- 29: Icicle expiration time
    		icicles[i].icicle = false
    		-- TODO: decrease total dmg stored with the dmg stored in deactivated icicle frame
    		addon:UpdateFrames()
    		self = nil -- icFrame.timer = nil
    	end)
    end

    function addon:DamageTotal(reset)
        local num   = 0
        local total = _G[aName..'icetotal']
        local n

        for i = 1, 5 do
            if icicles[i].damage then
                num = num + icicles[i].damage
            end
        end

        if  iipGSTooltip then
            iipGSTooltip:SetSpellByID(199786)
            local text = iipGSTooltipTextLeft4:GetText()
            if text then
                n = text:match'dealing (.-) damage plus the damage stored in your Icicles'
                if  n then
                    n = n:gsub(' [A-z ]*', '')
                    n = n:gsub(',', '')
                    n = tonumber(n)
                    if icicles[5].damage and icicles[5].damage > 0 then num = num + n end
                end
            end
        end

        total.t:SetText(num)

        if  reset then
            for i = 1, 5 do
                if icicles[i].damage then icicles[i].damage = 0 end
            end
            num = 0
            total.t:SetText''
        end
    end

    -- insert damage amounts for each icicle based on our equation.
    function addon:Damage(i)
        local amount = icicles[i].base > 0 and math.floor(icicles[i].base/100*self.player_mastery) or 0
        icicles[i].damage  = amount
        icicles[i].t:SetText(amount > 0 and amount or '')
        icicles[i].t:Show()
        self:DamageTotal()
    end

    -- Update icicle count & dmg for frames
    function addon:UpdateFrames(startTimer, damage)
    	local i = 1

    	-- I've reverted this whole function back to an old version by memory.
    	-- Stuff probably missing and needs changing.

    	while i <= 5 do
    		if  icicles[i].icicle then -- If icicle exist
    			-- enable icicle frame
    			icicles[i].icon:SetAlpha(1)
                if  icicles[i].base == 0 then -- is empty or reset
                    icicles[i].base = damage
                end
                if  damage == 0 then
                    icicles[i].base = 0
                end
    			if startTimer then
    				--if not icicles[i].timer then
    					self:Timer(i)
                        self:Damage(i)
    				--end
    			end
    		else
    			-- deactivate
    			icicles[i].icon:SetAlpha(0)
                icicles[i].t:Hide()
                icicles[i].base = 0
    		end

    		if i == 5 then
    			-- TODO: Add update for stored damage count
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

    function addon:COMBAT_LOG_EVENT_UNFILTERED(_, _, etype, _, srcGUID, _, _, _, _, _, _, _, id, _, _, damage)
        if not srcGUID or srcGUID ~= self.player_GUID then return end   -- Spell not cast by player
        if not spellcache[id] then return end                               -- Wrong spell ID

        --[[local now = GetTime()
        if self.lastEvent and ((now - self.lastEvent) <= .9) then return end
        self.lastEvent = now]]

        if etype
        and (
            (id == 228597 and etype == 'SPELL_DAMAGE')
            or
            ((id == 30455 or id == 199786) and etype == 'SPELL_CAST_SUCCESS')
            ) then
        	-- increment
        	if  id == 228597 then
        		if icicles[5].icicle then  -- max amount reached
        			-- TODO: remove dmg from oldest icicle
        			self:UpdateFrames(true, damage)
        			return   -- stop func
        		end

        		for i = 1, 5 do
        			if not icicles[i].icicle then
        				icicles[i].icicle = true
        				break -- Stop loop
        			end
        		end

        		-- TODO: increment icicle damage count and text
        		-- damage/self.player_mastery*100 ?
        		self:UpdateFrames(true, damage)
        		return

            -- decrement (icicle)
        elseif  id == 30455 or id == 199786 then
        		if not icicles[1].icicle then return end -- do not decrement if no icicle exists
        		for i = 5, 1, -1 do -- reverse count
        			if  icicles[i].timer then
        				icicles[i].timer:Cancel()
        			end
        			icicles[i].icicle = false
                    self:DamageTotal(true)
        		end
        		self:UpdateFrames(true, 0)
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

    	if  select(2, IsInInstance()) == 'arena' then
    		-- This event is sometimes not called when disconnecting in an arena,
    		-- make sure the function is always run.
    		self:PLAYER_ENTERING_WORLD()
    	end

        -- init mastery value
        self:MASTERY_UPDATE()

    	-- Remove objects from memory
    	self.PLAYER_LOGIN = nil
    end

    addon:RegisterEvent'PLAYER_ENTERING_WORLD'
    addon:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

    hooksecurefunc(NamePlateDriverFrame, 'SetupClassNameplateBar', Parent)


    --
