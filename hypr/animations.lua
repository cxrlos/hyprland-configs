hl.config({ animations = { enabled = true } })

hl.curve("quickFade", { type = "bezier", points = {{0.15, 0.9}, {0.1, 1}} })
hl.curve("easeOut", { type = "bezier", points = {{0.25, 1}, {0.5, 1}} })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, bezier = "quickFade", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "quickFade", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "easeOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1, bezier = "quickFade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1, bezier = "quickFade" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.5, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "easeOut", style = "slidefade 6%" })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "borderangle", enabled = false })
