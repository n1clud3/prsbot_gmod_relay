net.Receive("prsbotDiscordMsg", function()
    local chatmsg = net.ReadString()
    if (string.len(chatmsg) == 0) then return end
    chat.AddText(
        Color(88, 101, 242), "[Discord] ",
        Color(255, 255, 255), chatmsg
    )
end)