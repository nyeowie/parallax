GM.Name = "Parallax"
GM.Author = "Riggs"
GM.Description = "Parallax is a modular roleplay framework for Garry's Mod, built for performance, structure, and developer clarity."
GM.Version = "Alpha 0.1.0"

ax.util:Print("Framework Initializing...")
ax.util:LoadFolder("parallax/gamemode/external", true)
ax.util:LoadFolder("parallax/gamemode/external/paint", true)
ax.util:LoadFolder("libraries")
ax.util:LoadFolder("libraries/client")
ax.util:LoadFolder("libraries/server")
ax.util:LoadFolder("system")
ax.util:LoadFolder("meta")
ax.util:LoadFolder("ui")
ax.util:LoadFolder("hooks")
ax.util:LoadFolder("net")
ax.util:LoadFolder("languages")
ax.util:Print("Framework Initialized.")

function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")