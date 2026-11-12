local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local BASE = "/mnt/us/btkeepalive"
local EXT = "/mnt/us/extensions/btkeepalive"

local BTKeepalive = WidgetContainer:extend{
    name = "btkeepalive",
    is_doc_only = false,
}

function BTKeepalive:init()
    self.ui.menu:registerToMainMenu(self)
end

function BTKeepalive:addToMainMenu(menu_items)
    menu_items.btkeepalive = {
        text = _("Bluetooth Keepalive"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text = _("Get MAC Address"),
                callback = function() self:getMACAddress() end,
            },
            {
                text = _("Current Mode"),
                callback = function() self:getCurrentMode() end,
            },
            {
                text = _("Reading Mode"),
                callback = function() self:setReadingMode() end,
            },
            {
                text = _("Always On"),
                callback = function() self:setAlwaysOn() end,
            },
            {
                text = _("Default (Disable)"),
                callback = function() self:setDefault() end,
            },
            {
                text = _("Diagnostics"),
                callback = function() self:showDiagnostics() end,
            },
        },
    }
end

-- Runs a command and returns its trimmed output ("" if it cannot be run).
local function capture(cmd)
    local p = io.popen(cmd .. " 2>/dev/null")
    if not p then return "" end
    local out = p:read("*a") or ""
    p:close()
    return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- The shell scripts hold all the logic (shared with the KUAL menu), so KOReader
-- and KUAL always behave the same.
local function needInstalled(script)
    if fileExists(script) then return true end
    UIManager:show(InfoMessage:new{
        text = _("Script not found:\n") .. script
            .. _("\nCopy the btkeepalive and extensions folders to /mnt/us/."),
    })
    return false
end

function BTKeepalive:getMACAddress()
    local script = BASE .. "/bin/paired.sh"
    if not needInstalled(script) then return end
    local out = capture("/bin/sh " .. script)
    if out == "" then
        UIManager:show(InfoMessage:new{
            text = _("No paired devices found.\nPair via Settings → Bluetooth first."),
        })
        return
    end
    UIManager:show(InfoMessage:new{
        text = _("Paired Bluetooth Devices:\n\n") .. out,
    })
end

function BTKeepalive:getCurrentMode()
    local script = BASE .. "/bin/status.sh"
    if not needInstalled(script) then return end
    local out = capture("/bin/sh " .. script)
    UIManager:show(InfoMessage:new{
        text = (out ~= "" and out) or _("Unknown"),
        timeout = 5,
    })
end

function BTKeepalive:setReadingMode()
    self:runShell(EXT .. "/set_reading.sh",
        _("Reading Mode enabled\nReconnects after each drop.\nThe Kindle sleeps normally."))
end

function BTKeepalive:setAlwaysOn()
    self:runShell(EXT .. "/set_always_on.sh",
        _("Always On enabled\nKeeps the Kindle awake and\nreconnects after each drop."))
end

function BTKeepalive:setDefault()
    self:runShell(EXT .. "/set_default.sh", _("Disabled (default mode)"))
end

-- Runs a mode switch. Shows a "please wait" box first (the scripts need a few
-- seconds and os.execute blocks the UI) and reports the real outcome.
function BTKeepalive:runShell(script, msg)
    if not needInstalled(script) then return end

    local wait = InfoMessage:new{ text = _("Please wait…") }
    UIManager:show(wait)
    UIManager:forceRePaint()

    local ok = os.execute("/bin/sh " .. script .. " >/dev/null 2>&1")
    -- LuaJIT returns the exit status, Lua 5.2+ returns true/nil.
    local success = (ok == 0) or (ok == true)

    UIManager:close(wait)

    if not success then
        UIManager:show(InfoMessage:new{
            text = _("Could not switch mode.\nSee /mnt/us/btkeepalive/log/wrapper.log"),
        })
        return
    end

    -- Append anything worth knowing (e.g. "waiting: MAC address not set").
    local status = capture("/bin/sh " .. BASE .. "/bin/status.sh")
    local extra = status:match("\n(.+)$")
    if extra then msg = msg .. "\n\n" .. extra end

    UIManager:show(InfoMessage:new{ text = msg, timeout = 4 })
end

function BTKeepalive:showDiagnostics()
    local script = BASE .. "/bin/diagnose.sh"
    if not needInstalled(script) then return end
    local out = capture("/bin/sh " .. script)
    local ok, TextViewer = pcall(require, "ui/widget/textviewer")
    if ok and TextViewer then
        UIManager:show(TextViewer:new{
            title = _("BT Keepalive diagnostics"),
            text = out,
        })
    else
        UIManager:show(InfoMessage:new{ text = out })
    end
end

return BTKeepalive
