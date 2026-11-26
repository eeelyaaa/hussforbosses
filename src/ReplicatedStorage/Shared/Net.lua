--!strict
-- Net: every remote in the game, created in one place, with its payload contract written beside it.
-- Skeleton at M0 (tech-lead). The remotes themselves and their payloads are B8, filled at M1 and M2 by the
-- tech-lead's remotes contract (team/requirements/) and built by the scripter.
--
-- Conventions (team/decisions.md, M0):
--   * Instances live at ReplicatedStorage.Remotes.<Family>.<Name>; only the server creates them (Net.serverInit).
--   * Name = what happens, as a verb or noun phrase in PascalCase: Punch.Report, Punch.Result, Fight.Start.
--   * kind = "event" (RemoteEvent), "unreliable" (UnreliableRemoteEvent, for cosmetic broadcasts only) or
--     "function" (RemoteFunction, only for Shop.Open's quotes; never server-to-client).
--   * dir = "c2s", "s2c" or "both". Every c2s remote validates type, range, rate, state and distance on the
--     server before anything else (roblox-networking skill). No client value is trusted except the burst
--     report's grade and tap time, which the server bounds (build plan, "Client and server boundaries").
--   * Each entry carries a one-line payload comment: argument order and types.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type Kind = "event" | "unreliable" | "function"
export type Dir = "c2s" | "s2c" | "both"
export type Spec = { kind: Kind, dir: Dir, payload: string }

local Net = {}

-- The families (build plan, "Remotes, by family"). Entries are added at M1/M2.
Net.FAMILIES = {
	Punch = {} :: { [string]: Spec },
	Fight = {} :: { [string]: Spec },
	Bag = {} :: { [string]: Spec },
	Base = {} :: { [string]: Spec },
	Boss = {} :: { [string]: Spec },
	Carry = {} :: { [string]: Spec },
	Steal = {} :: { [string]: Spec },
	Shield = {} :: { [string]: Spec },
	Zones = {} :: { [string]: Spec },
	Rebirth = {} :: { [string]: Spec },
	Shop = {} :: { [string]: Spec },
	Offline = {} :: { [string]: Spec },
	Profile = {} :: { [string]: Spec },
}

local CLASS = { event = "RemoteEvent", unreliable = "UnreliableRemoteEvent", ["function"] = "RemoteFunction" }

-- Server only, once, from Main.server.lua, before any system starts.
function Net.serverInit()
	assert(RunService:IsServer(), "Net.serverInit is server only")
	local root = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	root.Name = "Remotes"
	for family, specs in pairs(Net.FAMILIES) do
		local folder = root:FindFirstChild(family) or Instance.new("Folder")
		folder.Name = family
		for name, spec in pairs(specs) do
			if not folder:FindFirstChild(name) then
				local r = Instance.new(CLASS[spec.kind])
				r.Name = name
				r.Parent = folder
			end
		end
		folder.Parent = root
	end
	root.Parent = ReplicatedStorage
end

-- Either side: the remote instance for Family.Name. Errors on a name that is not in FAMILIES.
function Net.get(family: string, name: string): Instance
	local specs = Net.FAMILIES[family]
	assert(specs and specs[name], ("Net: no remote %s.%s in the contract"):format(family, name))
	local root = ReplicatedStorage:WaitForChild("Remotes", 10)
	assert(root, "Net: ReplicatedStorage.Remotes missing (server not started?)")
	local r = (root :: Instance):WaitForChild(family):WaitForChild(name, 10)
	assert(r, ("Net: remote %s.%s not created"):format(family, name))
	return r :: Instance
end

return Net
