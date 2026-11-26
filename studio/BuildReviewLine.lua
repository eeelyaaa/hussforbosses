if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-32 BOSS REVIEW LINE (the manager's ask). STUDIO ONLY: never runs or exists in a live server (the guard script removes it there).
-- Builds Workspace.ReviewLine: a plain floor away from the play area (z -400, 100 up), CLONES of every Boss_<id> model in zone order,
-- an R15 and an R6 dummy at the end, name plates and "now playing" plates (studs, Ui/WorldLabel), a go pad by the hub spawn and a
-- return pad at the line. Runtime: LocalScript HFB_ReviewLine + ModuleScript HFB_ReviewLineDriver (StarterPlayerScripts, from
-- studio/review/) loop every boss through its moves and the dummies through the avatar clips, 1 s break between moves; Script
-- HFB_ReviewLineGuard (ServerScriptService) does the pads in Studio and deletes all of this in a live server.
-- Re-runnable: rebuilds from the current Boss_* models (run again after the bosses are re-imported / SetupBosses is re-run).
-- Needs the DevSync sync first (Controllers, WorldLabel, Skins) and SetupBosses.lua done.
--   require(game.ServerStorage.DevSync:Clone()).run("BuildReviewLine.lua")
-- To take it out before publishing: run RemoveReviewLine.lua.
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
local BASE = "http://127.0.0.1:34874/studio/review/"
local FLOOR_TOP, Z0, XC = 100, -400, 206
local fails = 0
local function check(l, ok, x) print(("BuildReviewLine: %s %s%s"):format(ok and "PASS" or "FAIL", l, x and (" (" .. x .. ")") or "")) if not ok then fails += 1 end end

-- clear the old line and scripts
for _, n in ipairs({ "ReviewLine" }) do local o = workspace:FindFirstChild(n) if o then o:Destroy() end end
for _, p in ipairs({ { SPS, "HFB_ReviewLine" }, { SPS, "HFB_ReviewLineDriver" }, { SSS, "HFB_ReviewLineGuard" } }) do
	local o = p[1]:FindFirstChild(p[2]) if o then o:Destroy() end
end

local Tokens = require(RS.Skins.brickbrawl.Tokens)
local Names = require(RS.Skins.brickbrawl.Names)
local C = Tokens.colors
local WorldLabel = require(SPS.Ui.WorldLabel)

-- sources: the gameplay bosses on the pads (not clones, not inside the line)
local sources = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Model") and d.Name:match("^Boss_z%d_t%d$") then table.insert(sources, d) end
end
table.sort(sources, function(a, b) return a.Name < b.Name end)
check("six bosses found", #sources == 6, #sources .. " found")

-- M2-34 streaming: the root is ONE Persistent Model (a Folder cannot carry a streaming mode), so the whole showcase (bosses, dummies, plates,
-- floor) reaches the client at join and is never streamed out. It is Studio-only and far from spawn, which is exactly what Default would drop. TEAM CALL M2-34-1.
local root = Instance.new("Model") root.Name = "ReviewLine" root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
local bossesF, dumF, plateF = Instance.new("Folder"), Instance.new("Folder"), Instance.new("Folder")
bossesF.Name, dumF.Name, plateF.Name = "Bosses", "Dummies", "Plates"
bossesF.Parent, dumF.Parent, plateF.Parent = root, root, root

local function anchorPart(name, cf, size, parent, col)
	local p = Instance.new("Part") p.Name = name p.Anchored = true p.CFrame = cf p.Size = size
	p.CanCollide = false p.CanQuery = false p.CanTouch = false p.Transparency = 1 p.Parent = parent
	return p
end
local function textLabel(parent, name, text, bg, fg)
	local f = Instance.new("Frame") f.Name = name f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = bg f.BorderSizePixel = 0 f.Parent = parent
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.2, 0) c.Parent = f
	local t = Instance.new("TextLabel") t.Name = "Label" t.Size = UDim2.fromScale(0.94, 0.8) t.Position = UDim2.fromScale(0.03, 0.1)
	t.BackgroundTransparency = 1 t.TextScaled = true t.Text = text t.TextColor3 = fg
	t.FontFace = Font.fromName("Montserrat", Enum.FontWeight.Heavy) t.Parent = f
	return f
end
-- two studs-sized plates on one anchor: the name, and below it "now playing"
-- y = height above the floor of the plate pair's centre: above the figure (head, halo and a rearing move), never in front of it
local function makePlate(name, title, x, z, width, y)
	local a = anchorPart("Plate_" .. name, CFrame.new(x, FLOOR_TOP + y, z), Vector3.new(1, 1, 1), plateF)
	local g1 = WorldLabel.new({ adornee = a, name = "Name", studsW = width, studsH = 2.6, offset = Vector3.new(0, 1.1, 0) })
	textLabel(g1, "Title", title, C.plateBlue, C.white)
	local g2 = WorldLabel.new({ adornee = a, name = "Now", studsW = width, studsH = 1.8, offset = Vector3.new(0, -1.1, 0) })
	textLabel(g2, "NowBox", "starting...", C.ink, C.flashYellow)
	return a
end

-- bosses: clones, no tags, facing +Z (rotated 180 degrees) so the viewer in front sees zone 1 on the left
local FACE = CFrame.Angles(0, math.pi, 0)
local slots, total = {}, 0
for _, src in ipairs(sources) do
	local m = src:Clone()
	m.ModelStreamingMode = Enum.ModelStreamingMode.Default -- the clone inherited Persistent from its source; inside the Persistent root it follows the root
	for _, d in ipairs(m:GetDescendants()) do for _, t in ipairs(CollectionService:GetTags(d)) do CollectionService:RemoveTag(d, t) end end
	for _, t in ipairs(CollectionService:GetTags(m)) do CollectionService:RemoveTag(m, t) end
	m:PivotTo(FACE)
	local _, sz = m:GetBoundingBox()
	local H = m:GetAttribute("H") or sz.Y
	local w = math.max(sz.X, sz.Z) + 0.7 * H + 6
	table.insert(slots, { m = m, w = w, H = H, top = sz.Y, name = m.Name, title = Names.creatures[m:GetAttribute("CreatureId")] or m.Name })
	total += w
end
local DUM_W = 14
total += DUM_W * 2 + 10
local x = XC - total / 2
local line0 = x
for _, s in ipairs(slots) do
	local cx = x + s.w / 2
	s.m:PivotTo(CFrame.new(cx, FLOOR_TOP, Z0) * FACE)
	s.m.Parent = bossesF
	makePlate(s.name, s.title, cx, Z0, math.min(s.w - 1, 16), s.top + 0.25 * s.H + 3)
	x += s.w
end
x += 10
-- dummies
for _, kind in ipairs({ "R15", "R6" }) do
	local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType[kind])
	rig.Name = kind
	local hum = rig:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	rig.HumanoidRootPart.Anchored = true
	local cx = x + DUM_W / 2
	rig:PivotTo(CFrame.new(cx, FLOOR_TOP + (rig:GetExtentsSize().Y / 2) + 0.05, Z0) * FACE)
	-- stand the feet on the floor
	local cf, sz = rig:GetBoundingBox()
	rig:PivotTo(rig:GetPivot() + Vector3.new(0, FLOOR_TOP - (cf.Y - sz.Y / 2), 0))
	rig.Parent = dumF
	makePlate(kind, kind == "R15" and "R15 Avatar" or "R6 Avatar", cx, Z0, 12, rig:GetExtentsSize().Y + 4)
	x += DUM_W
end
local line1 = x

-- floor and pads
local fx0, fx1, fz0, fz1 = line0 - 20, line1 + 20, Z0 - 25, Z0 + 70
local floor = Instance.new("Part") floor.Name = "Floor" floor.Anchored = true
floor.Size = Vector3.new(fx1 - fx0, 2, fz1 - fz0) floor.Position = Vector3.new((fx0 + fx1) / 2, FLOOR_TOP - 1, (fz0 + fz1) / 2)
floor.Color = C.laneGrey floor.Material = Enum.Material.SmoothPlastic floor.TopSurface = Enum.SurfaceType.Smooth floor.BottomSurface = Enum.SurfaceType.Smooth
floor.MaterialVariant = Tokens.stud.variantName floor.Parent = root
local function pad(name, cx, y, z, title)
	local p = Instance.new("Part") p.Name = name p.Anchored = true p.Size = Vector3.new(8, 0.4, 8) p.Position = Vector3.new(cx, y + 0.2, z)
	p.Color = C.arrowYellow p.Material = Enum.Material.SmoothPlastic p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth p.Parent = root
	local g = WorldLabel.new({ adornee = p, name = "Sign", studsW = 9, studsH = 2.2, offset = Vector3.new(0, 3, 0) })
	textLabel(g, "Title", title, C.plateBlue, C.white)
	return p
end
local mid = (line0 + line1) / 2
local ls = anchorPart("LineSpawn", CFrame.new(mid - 15, FLOOR_TOP + 0.4, Z0 + 45), Vector3.new(1, 1, 1), root)
pad("ReturnPad", mid + 15, FLOOR_TOP, Z0 + 45, "Back to the game")
local sp = workspace:FindFirstChild("SpawnLocation")
local hx, hy, hz = sp and sp.Position.X or 206, sp and sp.Position.Y or 0, sp and sp.Position.Z or 112
anchorPart("HomeSpawn", CFrame.new(hx, hy + 1, hz), Vector3.new(1, 1, 1), root)
local track = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("Track")
local trackTop = track and (track.Position.Y + track.Size.Y / 2) or (hy + 0.5)
pad("GoPad", hx + 12, trackTop, hz, "Boss review line") -- sits on the hub track beside the spawn, opposite faces (no coplanar pair)

-- scripts
local function mkScript(cls, name, file, parent)
	local s = Instance.new(cls) s.Name = name
	-- The runtime copies drop the place-guard first line: it is for build scripts, and on a client it ran before the workspace
	-- attribute had replicated and killed the launcher (found at M2-32, plates stuck on "starting..."). They gate on IsStudio instead.
	local text = HttpService:GetAsync(BASE .. file, true)
	local nl = text:find("\n", 1, true)
	s.Source = text:sub(nl + 1)
	s.Parent = parent
	return s
end
local mod = mkScript("ModuleScript", "HFB_ReviewLineDriver", "Driver.lua", SPS)
local ls2 = mkScript("LocalScript", "HFB_ReviewLine", "Launcher.lua", SPS)
local gs = mkScript("Script", "HFB_ReviewLineGuard", "Guard.lua", SSS)
root.Parent = workspace

-- checks
check("review line root is a Persistent Model (M2-34)", root:IsA("Model") and root.ModelStreamingMode == Enum.ModelStreamingMode.Persistent)
check("floor clear of the play area", fz1 < 0 and floor.Position.Y > 50)
local ov = workspace:GetPartBoundsInBox(CFrame.new(hx + 12, trackTop + 1.5, hz), Vector3.new(8, 2, 8))
local others = 0 for _, p in ipairs(ov) do if not p:IsDescendantOf(root) and p ~= workspace.Terrain then if not (p.Name == "Track" and p.Parent == workspace.Hub) then others += 1 end end end
check("go pad overlaps nothing in the hub", others == 0, others .. " parts overlap")
for _, s in ipairs(slots) do
	local cf, sz = s.m:GetBoundingBox()
	check(s.name .. " feet on floor", math.abs((cf.Y - sz.Y / 2) - FLOOR_TOP) < 0.1, ("%.3f"):format(cf.Y - sz.Y / 2 - FLOOR_TOP))
end
print(("BuildReviewLine: line x %.1f..%.1f, %d bosses, 2 dummies, %d failed"):format(line0, line1, #slots, fails))
