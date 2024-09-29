local addon_name = "prsbot_gmod_relay"
local wsMethods = {
    AvatarFetch = "prsbotAvatarFetch",
    MessageSend = "prsbotMessageSend"
}

local function websocket_mode()
    require("gwsockets")

    local ws = GWSockets.createWebSocket(PRSBOT_WEBSOCKET_LINK)

    function ws:onDisconnected()
        print("[PrsBot Gmod Relay] WS disconnected. Retrying connection after 5 seconds.")

        timer.Simple(5, function() self:open() end)
    end

    function ws:onConnected()
        print("[PrsBot Gmod Relay] websocket successfully connected!")
        gameevent.Listen("player_say")
        hook.Add("player_say", addon_name, function(data)
            print("[PrsBot Gmod Relay] sending websocket message")
            if (data.teamonly == 0) then
                local ply = Player(data.userid)
                local payload = wsMethods.AvatarFetch .. util.TableToJSON({
                    plyname = ply:Nick(),
                    plysteamid = ply:SteamID64(),
                    plymsg = data.text
                })
                ws:write(payload)
            end
        end)
    end

    function ws:onMessage(msg)
        if (string.StartsWith(msg, wsMethods.MessageSend)) then
            local chatmsg = "[discord] " .. string.sub(msg, string.len(wsMethods.MessageSend) + 1)
            PrintMessage(HUD_PRINTTALK, chatmsg)
        end
    end


    hook.Add("Initialize", addon_name, function()
        ws:closeNow()
        ws:open()
        print("[PrsBot Gmod Relay] Opened connection to bot.")
    end)
end

local function polling_mode()
    print("WIP")
end

if (PRSBOT_MSG_RECEIVING_MODE == "websocket") then
    websocket_mode()
elseif (PRSBOT_MSG_RECEIVING_MODE == "polling") then
    polling_mode()
end