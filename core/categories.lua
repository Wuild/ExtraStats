local name, stats = ...;

stats.categories = {
    {
        id = "attributes",
        categoryFrame = "AttributesCategory",
        stats = {
            {
                stat = "HEALTH",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetHealth(statFrame, unit);
                end
            },
            {
                stat = "POWER",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetPower(statFrame, unit);
                end
            },
            {
                stat = "STRENGTH",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetStat(statFrame, unit, LE_UNIT_STAT_STRENGTH);
                end
            },
            {
                stat = "AGILITY",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetStat(statFrame, unit, LE_UNIT_STAT_AGILITY);
                end
            },
            {
                stat = "STAMINA",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetStat(statFrame, unit, LE_UNIT_STAT_STAMINA);
                end
            },
            {
                stat = "INTELLECT",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetStat(statFrame, unit, LE_UNIT_STAT_INTELLECT);
                end
            },
            {
                stat = "SPIRIT",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetStat(statFrame, unit, LE_UNIT_STAT_SPIRIT);
                end
            }
        },
    },
    {
        id = "melee",
        categoryFrame = "MeleeCategory",
        showFunc = function(unit)
            if ExtraStats.db.char.dynamic then
                return ExtraStats:IsMelee() and (CURRENT_ROLE == "DAMAGER" or CURRENT_ROLE == "TANK")
            end

            return true
        end,
        stats = {
            {
                stat = "DAMAGE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetDamage(statFrame, unit)
                    statFrame:SetScript("OnEnter", function()
                        ExtraStats.stats:DamageFrame_OnEnter(statFrame)
                    end);
                end
            },
            {
                stat = "ATTACKSPEED",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetAttackSpeed(statFrame, unit)
                end
            },
            {
                stat = "ATTACKPOWER",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetAttackPower(statFrame, unit)
                end
            },
            {
                stat = "HITRATING",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:MeleeHitChance(statFrame, unit)
                end
            },
            {
                stat = "CRITCHANCE",
                hideAt = 0,
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetMeleeCritChance(statFrame, unit)
                end
            },
            {
                stat = "HASTE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetMeleeHaste(statFrame, unit)
                end
            }
        }
    },
    {
        id = "ranged",
        categoryFrame = "RangedCategory",
        showFunc = function(unit)
            if ExtraStats.db.char.dynamic then
                return ExtraStats:IsRanged()
            end

            return true
        end,
        stats = {
            {
                stat = "RANGED_DAMAGE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetRangedDamage(statFrame, unit)
                    statFrame:SetScript("OnEnter", function()
                        ExtraStats.stats:RangedDamageFrame_OnEnter(statFrame)
                    end);
                end
            },
            {
                stat = "RANGED_ATTACKSPEED",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetRangedAttackSpeed(statFrame, unit)
                end
            },
            {
                stat = "RANGED_ATTACKPOWER",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetRangedAttackPower(statFrame, unit)
                end
            },
            {
                stat = "RANGED_HITRATING",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:MeleeHitChance(statFrame, unit)
                end
            },
            {
                stat = "RANGED_CRITCHANCE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetRangedCritChance(statFrame, unit)
                end
            },
        }
    },
    {
        id = "spell",
        categoryFrame = "SpellCategory",
        showFunc = function()
            if ExtraStats.db.char.dynamic then
                return ExtraStats:IsSpellUser() and CURRENT_ROLE ~= "TANK"
            end

            return true
        end,
        stats = {
            {
                stat = "SPELL_DAMAGE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetSpellBonusDamage(statFrame, unit)
                    statFrame:SetScript("OnEnter", function()
                        ExtraStats.stats:SpellBonusDamage_OnEnter(statFrame)
                    end);
                end
            },
            {
                stat = "SPELL_HEALING",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetSpellBonusHealing(statFrame, unit)
                end
            },
            {
                stat = "SPELL_HITRATING",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:MeleeHitChance(statFrame, unit)
                end
            },
            {
                stat = "SPELL_CRITCHANCE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetSpellCritChance(statFrame, unit)
                    statFrame:SetScript("OnEnter", function()
                        ExtraStats.stats:SpellCritChance_OnEnter(statFrame)
                    end);
                end
            },
            {
                stat = "SPELL_HASTE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetSpellHaste(statFrame, unit)
                end
            },
            {
                stat = "SPELL_REGEN",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetManaRegen(statFrame, unit)
                end
            }
        }
    },
    {
        id = "defenses",
        categoryFrame = "DefensesCategory",
        showFunc = function()
            if ExtraStats.db.char.dynamic then
                return CURRENT_ROLE == "TANK"
            end

            return true
        end,
        stats = {
            {
                stat = "ARMOR",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetArmor(statFrame, unit);
                end
            },
            {
                stat = "DEFENSE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetDefense(statFrame, unit);
                end
            },
            {
                stat = "DODGE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetDodge(statFrame, unit);
                end
            },
            {
                stat = "PARRY",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetParry(statFrame, unit);
                end
            },
            {
                stat = "BLOCK",
                showFunc = C_PaperDollInfo.OffhandHasShield,
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetBlock(statFrame, unit);
                end
            }
        }
    },
    {
        id = "enhancements",
        categoryFrame = "EnhancementsCategory",
        stats = {
            {
                stat = "EXPERTISE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetExpertise(statFrame, unit)
                end
            },
            {
                stat = "RESILIANCE",
                updateFunc = function(statFrame, unit)
                    ExtraStats.stats:SetResilience(statFrame, unit);
                end
            }
        },
    },
};