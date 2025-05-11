local MODULE = MODULE

ax.net:Hook("logging.send", function(payload)
    if ( !payload ) then return end

    ax.util:Print(ax.color:Get("log.message"), "Logging >> ", color_white, unpack(payload))
end)

function MODULE:Send(...)
    ax.util:Print(ax.color:Get("log.message"), "Logging >> ", color_white, ...)
end