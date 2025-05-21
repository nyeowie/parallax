MODULE.name = "Lua Refresh Detector"
MODULE.author = "Setsuna"
MODULE.description = "Detects client and server lua refresh events and announces them."

if SERVER then
    if not _G.ServerRefreshCount then
        _G.ServerRefreshCount = 0
    else
        _G.ServerRefreshCount = _G.ServerRefreshCount + 1
    end
end

if CLIENT then
    if not _G.ClientRefreshCount then
        _G.ClientRefreshCount = 0
    else
        _G.ClientRefreshCount = _G.ClientRefreshCount + 1
    end
end

if SERVER then
    local lastRefreshTime = lastRefreshTime or 0
    
    hook.Add("Initialize", "DetectServerLuaRefresh", function()
        if (SysTime() - lastRefreshTime) > 1 then
            lastRefreshTime = SysTime()
            
            timer.Simple(0.1, function()
                for _, v in ipairs(player.GetAll()) do
                    if IsValid(v) then
                        v:ChatPrint("[Server] Lua refresh detected. (Count: " .. _G.ServerRefreshCount .. ")")
                    end
                end
                print("[Server] Lua refresh detected. (Count: " .. _G.ServerRefreshCount .. ")")
            end)
        end
    end)
    
    hook.Add("Think", "ServerRefreshBackupChecker", function()
        hook.Remove("Think", "ServerRefreshBackupChecker")
        
        if (SysTime() - lastRefreshTime) > 1 then
            lastRefreshTime = SysTime()
            
            timer.Simple(0.1, function()
                for _, v in ipairs(player.GetAll()) do
                    if IsValid(v) then
                        v:ChatPrint("[Server] Lua refresh detected. (Count: " .. _G.ServerRefreshCount .. ")")
                    end
                end
                print("[Server] Lua refresh detected. (Count: " .. _G.ServerRefreshCount .. ")")
            end)
        end
    end)
end

if CLIENT then
    local lastRefreshTime = lastRefreshTime or 0
    
    hook.Add("Initialize", "DetectClientLuaRefresh", function()
        if (SysTime() - lastRefreshTime) > 1 then
            lastRefreshTime = SysTime()
            
            timer.Simple(0.1, function()
                chat.AddText(Color(255, 200, 0), "[Client] Lua refresh detected. (Count: " .. _G.ClientRefreshCount .. ")")
                print("[Client] Lua refresh detected. (Count: " .. _G.ClientRefreshCount .. ")")
            end)
        end
    end)
    
    hook.Add("HUDPaint", "ClientRefreshBackupChecker", function()
        hook.Remove("HUDPaint", "ClientRefreshBackupChecker")
        if (SysTime() - lastRefreshTime) > 1 then
            lastRefreshTime = SysTime()
            timer.Simple(0.1, function()
                chat.AddText(Color(255, 200, 0), "[Client] Lua refresh detected. (Count: " .. _G.ClientRefreshCount .. ")")
                print("[Client] Lua refresh detected. (Count: " .. _G.ClientRefreshCount .. ")")
            end)
        end
    end)
end