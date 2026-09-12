hl.config({ animations = { enabled = true } })

hl.curve("quickFade", { type = "bezier", points = {{0.15, 0.9}, {0.1, 1}} })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, curve = "quickFade", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, curve = "quickFade", style = "popin 95%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1, curve = "quickFade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1, curve = "quickFade" })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "workspaces", enabled = false })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })
