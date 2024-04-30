local _, ns = ...
local string_find = string.find
local addon = LibStub("AceAddon-3.0"):GetAddon("AdiBags")
local L = setmetatable({}, {__index = addon.L})
local C_TooltipInfo_GetBagItem = C_TooltipInfo and C_TooltipInfo.GetBagItem
local TooltipUtil_SurfaceArgs = TooltipUtil and TooltipUtil.SurfaceArgs

local function create()
  local tip, leftTip, rightTip = CreateFrame("GameTooltip"), {}, {}
  for x = 1,6 do
    local L,R = tip:CreateFontString(), tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L,R)
    leftTip[x] = L
    rightTip[x] = R
  end
  tip.leftTip = leftTip
  tip.rightTip = rightTip
  return tip
end

local tooltip = tooltip or create()

-- The filter itself

local setFilter = addon:RegisterFilter("UpgradeLevel", 62, 'ABEvent-1.0')
setFilter.uiName = L['UpgradeLevel']
setFilter.uiDesc = L['Group items based on their upgrade level.']

function setFilter:OnInitialize()
  self.db = addon.db:RegisterNamespace('UpgradeLevel', {
    profile = { enable = true, level = 800 },
    char = {  },
  })
end

function setFilter:Update()
  self:SendMessage('AdiBags_FiltersChanged')
end

function setFilter:OnEnable()
  addon:UpdateFilters()
end

function setFilter:OnDisable()
  addon:UpdateFilters()
end

-- Tooltip used for scanning.
-- Let's keep this name for all scanner addons.
local _SCANNER = "AVY_ScannerTooltip"
local Scanner
if not addon.WoW10 then
	-- This is not needed on WoW10, since we can use C_TooltipInfo
	Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, UIParent, "GameTooltipTemplate")
end

-- Cache of information objects,
-- globally available so addons can share it.
local Cache = AVY_ItemBindInfoCache or {}
AVY_ItemBindInfoCache = Cache

function setFilter:Filter(slotData)

	local bag, slot, quality, itemId = slotData.bag, slotData.slot, slotData.quality, slotData.itemId

	local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = GetItemInfo(itemId)

  local level = self:GetItemCategory(bag, slot)
  return level
end


function setFilter:GetItemCategory(bag, slot)
	local category = nil

  -- New API in WoW10 means we don't need an actual frame for the tooltip
  -- https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
  Scanner = C_TooltipInfo_GetBagItem(bag, slot)
  -- The SurfaceArgs calls are required to assign values to the 'leftText' fields seen below.
  TooltipUtil_SurfaceArgs(Scanner)
  for _, line in ipairs(Scanner.lines) do
    TooltipUtil_SurfaceArgs(line)
  end
  for i = 2, 6 do
    local line = Scanner.lines[i]
    if (not line) then
      break
    end

    local dfs3 = line.leftText:match("Dragonflight Season 3")
    if dfs3 ~= nil then
      return "Dragonflight Season 3"
    end

    local dfs2 = line.leftText:match("Dragonflight Season 2")
    if dfs2 ~= nil then
      return "Dragonflight Season 2"
    end

    local explorer = line.leftText:match("^Upgrade Level: Explorer")
    if explorer ~= nil then
      return "Explorer"
    end

    local adventurer = line.leftText:match("^Upgrade Level: Adventurer")
    if adventurer ~= nil then
      return "Adventurer"
    end

    local veteran = line.leftText:match("^Upgrade Level: Veteran")
    if veteran ~= nil then
      return "Veteran"
    end

    local champion = line.leftText:match("^Upgrade Level: Champion")
    if champion ~= nil then
      return "Champion"
    end

    local hero = line.leftText:match("^Upgrade Level: Hero")
    if hero ~= nil then
      return "Hero"
    end

    local myth = line.leftText:match("^Upgrade Level: Myth")
    if myth ~= nil then
      return "Myth"
    end

    local awakened = line.leftText:match("^Upgrade Level: Awakened")
    if awakened ~= nil then
      return "Awakened"
    end
  end

	return category
end

function setFilter:GetOptions()
  return {
    enable = {
      name = L['Enable UpgradeLevel'],
      desc = L['Check this if you want to group items by track.'],
      type = 'toggle',
      order = 10,
    },
  }, addon:GetOptionHandler(self, false, function() return self:Update() end)
end
