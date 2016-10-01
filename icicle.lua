

    local aName, ns = ...

    -- *.*°.*°...*°.°*..*. CONFIG *..*..**.*
    local size = 15    --   icon size
    -- ......***.*.*..°.*.*.***.*°.*.*°*.*

    local icicles = {}

    local ice = CreateFrame('Frame', aName, UIParent)
    ice:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)

    local CheckClassSpec = function()
    	local _, class = UnitClass'player'
        ice:Hide()
    	if class == 'MAGE' then
    		local spec = GetSpecialization()
    		if currentSpec == 3 then
    			ice:Show()
    		end
    	end
    end

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
    end

    --  wipe icicle instance for re-use
    local SetDamageEmpty = function(icicle)
        if icicle.timer ~= nil then icicle.timer:Cancel() end
        icicle.basedamage = 0
        -- icicle.Timer = nil
        icicle.timestamp = 0
        icicle.bu.t:SetText(0)
        icicle.bu.cd:SetCooldown(0, 0)
    end

    --  ice lance or glacial spike has been cast
    local ShootIcicles = function()
        local max = 999999999999
        local index = 0
        for i = 1, 5 do
            if icicles[i].basedamage > 0 then
                if icicles[i].timestamp < max then
                    index = i
                    max = icicles[i].timestamp
                end
            end
        end

        if  index > 0 then
            SetDamageEmpty(icicles[index])
            C_Timer.After(.75, ShootIcicles)
        end
    end

    --  fish for events in combat log
    local CombatLogFilter = function(self, event, ...)
    	local name, realm = UnitName'player'
    	local timestamp, type, _, _, sourceName = select(1, ...)
    	if name == sourceName and type == 'SPELL_DAMAGE' then
    		local id = select(12, ...)
    		if  id == 228597 then                 --  frostbolt
    			local damage = select(15, ...)
    			SetupNewIcicle(damage, timestamp)
    		end
    	end
    	if name == sourceName and type == 'SPELL_CAST_SUCCESS' then
    		local id = select(12, ...)
    		if id == 30455 or id == 1000091 then  --  ice lance + glacial spike
    			ShootIcicles()
    		end
    	end
    end

    -- create a new icicle instance
    local SetupNewIcicle = function(damage, timestamp)
    	local tempstamp = 999999999999
    	local index     = 0

    	for i = 1, 5 do
    		if  icicles[i].basedamage == 0 then
    			index = i
    			break
    		end
    		if  icicles[i].timestamp < tempstamp then
    			index = i
    			timestamp = icicles[i].timestamp
    		end
    	end

    	if  icicles[index].basedamage > 0 then
    		icicles[index].timer:Cancel()
    	end

    	icicles[index].basedamage = damage
    	icicles[index].timer      = C_Timer.NewTimer(30, function() SetDamageEmpty(icicles[index]) end)
    	icicles[index].timestamp  = timestamp
    	icicles[index].bu.cd:SetCooldown(GetTime(), 30)
    end


    local IciclesCycle = function()
    	local mastery, coefficient = GetMasteryEffect()
    	local totalIcicleDamage = 0
    	for i = 1, 5 do
    		local icicleDamage = ((icicles[i].basedamage)/100)*mastery
    		icicle[i].bu.t:SetText(math.floor(icicleDamage))
    		totalIcicleDamage = totalIcicleDamage + icicleDamage
    	end
    	icicle[6].bu.t:SetText(math.floor(totalIcicleDamage))
    	C_Timer.After(.1, IciclesCycle)
    end

    local LoadIcicles = function()
        C_Timer.After(.1, IciclesCycle)
        CheckClassSpec()
    end

    ice:ACTIVE_TALENT_GROUP_CHANGED = CheckClassSpec
    ice:PLAYER_ENTERING_WORLD       = LoadIcicles
    ice:COMBAT_LOG_EVENT_UNFILTERED = function(self, event, ...)
        CombatLogFilter(self, event, ...)
    end

    ice:RegisterEvent'COMBAT_LOG_EVENT_UNFILTERED'
    ice:RegisterEvent'ACTIVE_TALENT_GROUP_CHANGED'
    ice:RegisterEvent'PLAYER_ENTERING_WORLD'


    --
