-- Gourmet_Prefer_*(itemA, itemB) returns:
-- true if itemA is better than itemB
-- false otherwise

function Gourmet_Prefer_SmallStacks(itemA, itemB)
    return itemA.stackSize < itemB.stackSize
end

function Gourmet_Prefer_Conjured(itemA, itemB)
    if itemA.conjured then
        return true
    end
end

function Gourmet_MakeComparatorWithCombinedCriteria(criteria)
    return function(itemA, itemB)
        for _, criterion in ipairs(criteria) do
            local aIsBetter = criterion(itemA, itemB)
            local bIsBetter = criterion(itemB, itemA)
            if aIsBetter and not bIsBetter then
                return true
            end
            if bIsBetter and not aIsBetter then
                return false
            end
        end
        return false
    end
end

-- Gourmet_Is_*(item) returns:
-- true if item matches criterion
-- false otherwise

function Gourmet_Is_Conjured(item)
    return item.conjured
end

function Gourmet_Is_BuffFood(item)
    return item.hasBuff
end

function Gourmet_ApplyRules(inputList, rulesForbidden, rulesRequired)
    local filteredList = {}
    for _, item in ipairs(inputList) do
        local rejected = false
        for _, rule in ipairs(rulesForbidden) do
            rejected = rejected or rule(item)
        end
        
        local allowed = true
        for _, rule in ipairs(rulesRequired) do
            allowed = allowed and rule(item)
        end
        
        if allowed and not rejected then
            table.insert(filteredList, item)
        end
    end
    return filteredList
end

function Gourmet_FilterConsumables()
    local foodRulesForbidden = { Gourmet_Is_BuffFood }
    local foodRulesRequired = {}
    
    local drinkRulesForbidden = {}
    local drinkRulesRequired = {}
    
    Gourmet_allFood = Gourmet_ApplyRules(Gourmet_allFood, foodRulesForbidden, foodRulesRequired)
    Gourmet_allDrinks = Gourmet_ApplyRules(Gourmet_allDrinks, drinkRulesForbidden, drinkRulesRequired)
end

function Gourmet_SortConsumables()
    local foodPreferences = { Gourmet_Prefer_Conjured, Gourmet_Prefer_SmallStacks }
    local drinkPreferences = { Gourmet_Prefer_Conjured, Gourmet_Prefer_SmallStacks }
    
    local foodComparator = Gourmet_MakeComparatorWithCombinedCriteria(foodPreferences)
    table.sort(Gourmet_allFood, foodComparator)
    
    local drinkComparator = Gourmet_MakeComparatorWithCombinedCriteria(drinkPreferences)
    table.sort(Gourmet_allDrinks, drinkComparator)
    
    -- Gourmet_Debug("Food ranking:")
    -- for rank, food in ipairs(Gourmet_allFood) do
    --     Gourmet_Debug("  " .. rank .. ": " .. food.name .. " x" .. food.stackSize)
    -- end
    -- Gourmet_Debug("Drink ranking:")
    -- for rank, drink in ipairs(Gourmet_allDrinks) do
    --     Gourmet_Debug("  " .. rank .. ": " .. drink.name .. " x" .. drink.stackSize)
    -- end
end
