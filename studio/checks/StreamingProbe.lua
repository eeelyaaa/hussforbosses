if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-34 installer. Edit mode, holding the studio lock:  require(game.ServerStorage.DevSync:Clone()).run("checks/StreamingProbe.lua")
-- Puts the client probe (LocalScript HFB_StreamingProbe), the RemoteEvent StreamProbe and a server listener (Script HFB_StreamingProbeSrv) in
-- the place. Then start play (start_stop_play), wait ~70 s, read the console for "STREAMPROBE" lines, stop play, and run
-- checks/StreamingProbeRemove.lua. Needs BuildReviewLine.lua run first (the review-line leg). Never leave the probe in the place.
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local SPS = game:GetService("StarterPlayer").StarterPlayerScripts
local SSS = game:GetService("ServerScriptService")
for _, n in ipairs({ "HFB_StreamingProbe" }) do local o = SPS:FindFirstChild(n) if o then o:Destroy() end end
for _, n in ipairs({ "HFB_StreamingProbeSrv" }) do local o = SSS:FindFirstChild(n) if o then o:Destroy() end end
local o = RS:FindFirstChild("StreamProbe") if o then o:Destroy() end
local ev = Instance.new("RemoteEvent") ev.Name = "StreamProbe" ev.Parent = RS
local text = HttpService:GetAsync("http://127.0.0.1:34874/studio/checks/StreamingProbe.client.lua", true)
local nl = text:find("\n", 1, true)
local ls = Instance.new("LocalScript") ls.Name = "HFB_StreamingProbe" ls.Source = text:sub(nl + 1) ls.Parent = SPS
local srv = Instance.new("Script") srv.Name = "HFB_StreamingProbeSrv"
srv.Source = 'game.ReplicatedStorage:WaitForChild("StreamProbe").OnServerEvent:Connect(function(_, line) print("STREAMPROBE-SRV " .. tostring(line)) end)'
srv.Parent = SSS
print("StreamingProbe: PASS installed (client probe, RemoteEvent, server listener)")
