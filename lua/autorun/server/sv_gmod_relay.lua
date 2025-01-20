local addon_name = "prsbot_gmod_relay"
local wsMethods = {
    PlayerSpawn = "prsbotPlayerSpawn",
    PlayerConnect = "prsbotPlayerConnect",
    PlayerLeave = "prsbotPlayerLeave",
    AvatarFetch = "prsbotAvatarFetch",
    MessageSend = "prsbotMessageSend",
    StatusCmd = "prsbotStatusCmd",
}

local function websocket_mode()
    require("gwsockets")

    local ws = GWSockets.createWebSocket(PRSBOT_WEBSOCKET_LINK)

    function ws:onDisconnected()
        print("[PrsBot Gmod Relay] WS disconnected. Retrying connection after 5 seconds.")

        timer.Simple(5, function() self:open() end)
    end

    function ws:onConnected()
        print("[PrsBot Gmod Relay] WS successfully connected!")
        hook.Remove("PlayerSay", "ZZZ" .. addon_name)
        hook.Add("PlayerSay", "ZZZ" .. addon_name, function(ply, text, teamchat)
            print("[PrsBot Gmod Relay] sending WS message", wsMethods.MessageSend)
            if (not teamchat) then
                local payload = wsMethods.AvatarFetch .. util.TableToJSON({
                    plyname = ply:Nick(),
                    plysteamid = ply:SteamID64(),
                    plymsg = text
                })
                ws:write(payload)
            end
        end)

        hook.Remove("PlayerConnect", addon_name)
        hook.Add("PlayerConnect", addon_name, function(name, ip)
            local payload = wsMethods.PlayerConnect .. util.TableToJSON({
                plyname = name
            })
            ws:write(payload)
        end)

        hook.Remove("PlayerInitialSpawn", addon_name)
        hook.Add("PlayerInitialSpawn", addon_name, function(ply)
            local payload = wsMethods.PlayerSpawn .. util.TableToJSON({
                plyname = ply:Nick(),
                plysteamid = ply:SteamID(),
                plysteamid64 = ply:SteamID64()
            })
            ws:write(payload)
        end)

        hook.Remove("PlayerDisconnected", addon_name)
        hook.Add("PlayerDisconnected", addon_name, function(ply)
            local payload = wsMethods.PlayerLeave .. util.TableToJSON({
                plyname = ply:Nick(),
                plysteamid = ply:SteamID(),
                plysteamid64 = ply:SteamID64()
            })
            ws:write(payload)
        end)
    end

    function ws:onMessage(msg)
        if (string.StartsWith(msg, wsMethods.MessageSend)) then
            net.Start("prsbotDiscordMsg")
            local chatmsg = string.sub(msg, string.len(wsMethods.MessageSend) + 1)
            net.WriteString(chatmsg)
            net.Broadcast()
        elseif (string.StartsWith(msg, wsMethods.StatusCmd)) then
            local payload = {}
            payload.hostname = GetHostName()
            payload.ipaddr = game.GetIPAddress()
            payload.maxplys = game.MaxPlayers()
            payload.curmap = game.GetMap()
            payload.players = {}
            for _, ply in ipairs(player.GetHumans()) do
                table.insert(payload.players, ply:Nick())
            end
            PrintTable(payload)
            ws:write(wsMethods.StatusCmd .. util.TableToJSON(payload))
        end
    end

    hook.Add("Initialize", addon_name, function()
        util.AddNetworkString("prsbotDiscordMsg")
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