--!nonstrict
-- Controllers/BossVisuals: clones of a boss model for the carried, dropped and placed boss (client-only visuals of
-- server state), and the hide/show of the pad boss. Templates are taken from the pad bosses at init, before any move
-- touches them (Fight.init defers its pad idle), so a clone is at rest pose.
--   BossVisuals.init()                  capture a template per CreatureId from the tagged pad bosses
--   BossVisuals.make(creatureId, scaleToMax?) -> Model?   a clone in workspace.HFB_ClientFx (tag HFB_Boss removed)
--   BossVisuals.source(creatureId) -> Model?              the pad boss (the original)
--   BossVisuals.hide(model) / BossVisuals.show(model)     LocalTransparencyModifier, this client only
--   BossVisuals.fx() -> Folder
local CollectionService = game:GetService("CollectionService")

local V = {}
local templates = {}

function V.fx(): Folder
	local f = workspace:FindFirstChild("HFB_ClientFx")
	if not f then
		f = Instance.new("Folder")
		f.Name = "HFB_ClientFx"
		f.Parent = workspace
	end
	return f
end

function V.source(creatureId: string): Model?
	local fx = workspace:FindFirstChild("HFB_ClientFx")
	for _, m in ipairs(CollectionService:GetTagged("HFB_Boss")) do
		if m:IsA("Model") and m:GetAttribute("CreatureId") == creatureId and not (fx and m:IsDescendantOf(fx)) then
			return m
		end
	end
	return nil
end

local function sanitize(m: Model)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then
			d.Transform = CFrame.identity
		end
	end
	CollectionService:RemoveTag(m, "HFB_Boss")
	-- the replicated copy can arrive without its PrimaryPart (found in the M1-14 play check): Body is the root group
	local body = m:FindFirstChild("Body", true)
	if body and body:IsA("BasePart") then
		m.PrimaryPart = body
	end
end

local GROUPS = { "Body", "Head", "Sig", "FistL", "FistR" }
-- All five groups and their joints are there (the model can arrive on the client before its children do).
local function complete(m: Model): boolean
	for _, g in ipairs(GROUPS) do
		if not m:FindFirstChild(g, true) then
			return false
		end
	end
	local joints = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then
			joints += 1
		end
	end
	return joints >= #GROUPS - 1
end

local function capture(m: Model): boolean
	local id = m:GetAttribute("CreatureId")
	if typeof(id) ~= "string" then
		return false
	end
	if templates[id] then
		return true
	end
	if not complete(m) then
		return false
	end
	local t = m:Clone()
	sanitize(t)
	templates[id] = t
	return true
end

-- Waits (up to 15 s) for a pad boss to arrive whole, then takes the template.
local function watch(m: Instance)
	if not m:IsA("Model") or m:IsDescendantOf(V.fx()) then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent and not capture(m) and os.clock() - t0 < 15 do
			task.wait(0.1)
		end
	end)
end

function V.init()
	for _, m in ipairs(CollectionService:GetTagged("HFB_Boss")) do
		watch(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Boss"):Connect(watch)
end

function V.make(creatureId: string, maxHeight: number?): Model?
	local t = templates[creatureId]
	if not t then
		local s = V.source(creatureId)
		if not s then
			return nil
		end
		capture(s) -- the pad boss may be posed by now; sanitize resets the joints and make() re-poses the body
		t = templates[creatureId]
	end
	if not t then
		return nil
	end
	local m = t:Clone()
	local h = m:GetAttribute("H")
	if maxHeight and typeof(h) == "number" and h > maxHeight then
		m:ScaleTo(maxHeight / h)
		m:SetAttribute("H", maxHeight)
	end
	m.Parent = V.fx()
	return m
end

local function setHidden(model: Instance, on: boolean)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = on and 1 or 0
		end
	end
end
function V.hide(model: Instance)
	setHidden(model, true)
end
function V.show(model: Instance)
	setHidden(model, false)
end

return V
