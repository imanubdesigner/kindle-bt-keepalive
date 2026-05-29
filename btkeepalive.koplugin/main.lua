local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

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
        },
    }
end

function BTKeepalive:getMACAddress()
    local f = io.open("/var/local/zbluetooth/bt_config.conf", "r")
    if not f then
        UIManager:show(InfoMessage:new{
            text = _("No paired devices found.\nPair via Settings → Bluetooth first."),
        })
        return
    end

    local macs = {}
    local names = {}
    local current_mac

    for line in f:lines() do
        local mac = line:match("^%[([0-9a-fA-F:]+)%]$")
        if mac then
            current_mac = mac
            table.insert(macs, mac)
        elseif current_mac then
            local name = line:match("^Name%s*=%s*(.+)$")
            if name then
                names[current_mac] = name
            end
        end
    end
    f:close()

    if #macs == 0 then
        UIManager:show(InfoMessage:new{
            text = _("No paired devices found."),
        })
        return
    end

    local start = math.max(1, #macs - 2)
    local lines = {}
    for i = start, #macs do
        local mac = macs[i]
        local name = names[mac]
        if name then
            table.insert(lines, mac .. " (" .. name .. ")")
        else
            table.insert(lines, mac)
        end
    end

    UIManager:show(InfoMessage:new{
        text = _("Paired Bluetooth Devices:\n\n") .. table.concat(lines, "\n"),
    })
end

function BTKeepalive:getCurrentMode()
    local f = io.open("/mnt/us/btkeepalive/config.conf", "r")
    if not f then
        UIManager:show(InfoMessage:new{
            text = _("Config file missing.\nPlease run setup first."),
        })
        return
    end

    local mode = f:read("*l")
    f:close()

    local mode_map = {
        reading = _("Reading Mode"),
        ["always-on"] = _("Always On Mode"),
        default = _("Default (Disabled)"),
    }
    local display = mode_map[mode]

    UIManager:show(InfoMessage:new{
        text = _("Current Mode: ") .. (display or _("Unknown")),
        timeout = 3,
    })
end

function BTKeepalive:setReadingMode()
    self:runShell("/mnt/us/extensions/btkeepalive/set_reading.sh", _("Reading Mode enabled"))
end

function BTKeepalive:setAlwaysOn()
    self:runShell("/mnt/us/extensions/btkeepalive/set_always_on.sh", _("Always On Mode enabled"))
end

function BTKeepalive:setDefault()
    self:runShell("/mnt/us/extensions/btkeepalive/set_default.sh", _("Disabled (default mode)"))
end

function BTKeepalive:runShell(script, msg)
    if not io.open(script, "r") then
        UIManager:show(InfoMessage:new{
            text = _("Script not found:\n") .. script,
        })
        return
    end
    os.execute("/bin/sh " .. script .. " 2>/dev/null")
    UIManager:show(InfoMessage:new{
        text = msg,
        timeout = 3,
    })
end

return BTKeepalive
