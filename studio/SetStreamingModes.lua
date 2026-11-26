if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- SetStreamingModes (M2-34): the streaming mode of every streamed Workspace model the client code reads whole. Re-runnable, idempotent; run it
-- after BuildSlice / BuildStrip / BuildHazards / SetupBosses (they create the models with the default mode).
--   require(game.ServerStorage.DevSync:Clone()).run("SetStreamingModes.lua")
-- TEAM CALL M2-34-1 (vault/roblox-docs/instance-streaming.md):
--   * Boss_* models (SetupBosses / BuildReviewLine set it): Persistent. The review line root is one Persistent Model.
--   * Plot models (Workspace.Plots.PlotN): Atomic. Base / Shield / Steal / Ring read BagPad, Crate, Bag, Spot_n and the bounding box of a plot as one thing.
--   * Hazard models (tag HFB_Hazard) and the non-Fixed boss pads (tag HFB_BossPad, Kind ~= fixed): Atomic, each is small and read as a unit.
--   * The Fixed pads stay Default: each holds a Persistent boss, and the client waits for the pad's parts (Pads, BossVisuals).
local CollectionService = game:GetService("CollectionService")
local fails, n = 0, 0
local function check(label, ok) print(("SetStreamingModes: %s %s"):format(ok and "PASS" or "FAIL", label)) if not ok then fails += 1 end end
local function atomic(m) if m:IsA("Model") then m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic n += 1 end end
local plots = workspace:FindFirstChild("Plots")
local np = 0
if plots then for _, m in ipairs(plots:GetChildren()) do if m:IsA("Model") then atomic(m) np += 1 end end end
local nh = 0
for _, m in ipairs(CollectionService:GetTagged("HFB_Hazard")) do if m:IsA("Model") then atomic(m) nh += 1 end end
local npad = 0
for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
	if m:IsA("Model") and m:GetAttribute("Kind") ~= "fixed" then atomic(m) npad += 1 end
end
check(("plots %d, hazards %d, rolling pads %d set Atomic"):format(np, nh, npad), np > 0 and nh > 0 and npad > 0)
local bad = 0
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Name:match("^Boss_z%d_t%d$") and m.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent and not m:IsDescendantOf(workspace.ReviewLine) then bad += 1 end
end
check("every Boss_* model outside the review line is Persistent", bad == 0)
print(("SetStreamingModes: %s, %d failed"):format(fails == 0 and "PASS" or "FAIL", fails))
