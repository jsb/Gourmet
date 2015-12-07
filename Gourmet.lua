Gourmet_allFood = {}
Gourmet_allDrinks = {}

SLASH_GOURMET1 = "/gourmet"

-- All food / drinks
-- name (string)
-- type (string): "food" or "drink"
-- bag (number): Bag index in which the item is stored
-- slot (number): Slot index inside the bag
-- stackSize (number)
-- conjured (boolean): Whether the consumable will disappear after some logout time
-- consumeTime (number): Maximum time spent consuming the item

-- Food
-- health (number): Total amount of health regenerated while eating
-- hasBuff (boolean): Whether the food will apply a buff after eating

-- Drinks
-- mana (number): Total amount of mana regenerated while eating

function GourmetFrame_OnEvent()
    Gourmet_ScanBags()
end

function Gourmet_Debug(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
end

function Gourmet_ProcessItem(bag, slot)
    local item = {}
    item.bag = bag
    item.slot = slot
    item.conjured = false
    
    local _, itemStackSize, _, _, _ = GetContainerItemInfo(bag, slot)
    item.stackSize = itemStackSize
    
    GourmetTooltip:ClearLines()
    GourmetTooltip:SetBagItem(bag, slot)
    item.name = GourmetTooltipTextLeft1:GetText()
    for line = 1, GourmetTooltip:NumLines() do
        local lineText = getglobal("GourmetTooltipTextLeft" .. line):GetText()
        
        -- detect foods
        local foodFound, _, foodHealth, foodConsumeTime = string.find(lineText, "Use: Restores (%d+) health over (%d+) sec.")
        if foodFound then
            item.type = "food"
            item.health = foodHealth
            item.consumeTime = foodConsumeTime
            item.hasBuff = false
        end
        
        -- detect drinks
        local drinkFound, _, drinkMana, drinkConsumeTime = string.find(lineText, "Use: Restores (%d+) mana over (%d+) sec.")
        if drinkFound then
            item.type = "drink"
            item.mana = drinkMana
            item.consumeTime = drinkConsumeTime
        end
        
        -- detect conjured items
        local conjuredFound = string.find(lineText, "^Conjured Item$")
        if conjuredFound then
            item.conjured = true
        end
        
        -- detect buff food
        if item.type == "food" then
            local buffFound = nil
            buffFound = buffFound or string.find(lineText, "If you spend at least 10 seconds eating")
            buffFound = buffFound or string.find(lineText, "Must remain seated while eating. Also")
            if buffFound then
                item.hasBuff = true
            end
        end
    end
    
    if item.type == "food" then
        table.insert(Gourmet_allFood, item)
    end
    if item.type == "drink" then
        table.insert(Gourmet_allDrinks, item)
    end
end

function Gourmet_ScanBags()
    Gourmet_allFood = {}
    Gourmet_allDrinks = {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemTexture, _, _, _, _ = GetContainerItemInfo(bag, slot)
            if itemTexture then
                Gourmet_ProcessItem(bag, slot)
            end
        end
    end
    Gourmet_FilterConsumables()
    Gourmet_SortConsumables()
end

function SlashCmdList.GOURMET(message)
    if message == "eat" then
        if table.getn(Gourmet_allFood) > 0 then
            local bestFood = Gourmet_allFood[1]
            local itemLink = GetContainerItemLink(bestFood.bag, bestFood.slot)
            Gourmet_Debug("Eating " .. itemLink .. ".")
            UseContainerItem(bestFood.bag, bestFood.slot)
        else
            Gourmet_Debug("Nothing to eat.")
        end
    end
    if message == "drink" then
        if table.getn(Gourmet_allDrinks) > 0 then
            local bestDrink = Gourmet_allDrinks[1]
            local itemLink = GetContainerItemLink(bestDrink.bag, bestDrink.slot)
            Gourmet_Debug("Drinking " .. itemLink .. ".")
            UseContainerItem(bestDrink.bag, bestDrink.slot)
        else
            Gourmet_Debug("Nothing to drink.")
        end
    end
end

function Gourmet_Init()
    GourmetFrame = CreateFrame("Frame")
    GourmetFrame:RegisterEvent("BAG_UPDATE")
    GourmetFrame:SetScript("OnEvent", GourmetFrame_OnEvent)

    CreateFrame("GameTooltip", "GourmetTooltip", nil, "GameTooltipTemplate")
    GourmetTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    GourmetTooltip:AddFontStrings(
        GourmetTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
        GourmetTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
    )
end

Gourmet_Init()
