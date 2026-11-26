--!strict
-- Data/Purchases: the purchase record (m2-contract.md C "Receipt rules", D "Receipts"; M2-02 M3).
-- Session.recordPurchase(player, purchaseId, grant) -> "granted" | "already" | "retry"
--   * "retry" at once (grant nothing; ProcessReceipt answers NotProcessedYet) when the player has no profile here,
--     it is still loading, it is a temp profile (nothing it got could be saved), or its leave or shutdown has begun.
--   * "already" when the id is in the profile's handled list: ProcessReceipt answers PurchaseGranted, nothing granted.
--   * Otherwise ONE UpdateAsync: the record is built from the live profile, `grant` (a pure op on a profile-shaped
--     table, no yields, no services) is applied to it, and the id appended, in the same write. Only after that write
--     succeeds is the same op applied to the live profile (with the id). A failed write returns "retry" and the live
--     profile was never changed. Effects outside the profile (toasts, shields, Shop.Grant) are the caller's, after.
--   * `grant` may write the protected fields a purchase owns (cash and boughtCash through Session.ops, crate entries
--     with a bought mark, starterPackGiven); boughtCash <= cash is enforced after it.
-- Session wires this module in (Purchases.init(core)).
local Purchases = {}

local core: any = nil

function Purchases.init(c: any)
	core = c
end

function Purchases.record(player: any, purchaseId: string, grant: (any) -> ()): string
	if typeof(purchaseId) ~= "string" or #purchaseId == 0 or #purchaseId > 100 or type(grant) ~= "function" then
		warn("[HFB] Session.recordPurchase: bad arguments")
		return "retry"
	end
	if not core.isLive(player) then
		return "retry"
	end
	local p = core.profile(player)
	if table.find(p.purchases, purchaseId) then
		return "already"
	end
	-- Session's save applies the grant to the live profile after the write succeeds and before it lets the next
	-- write build its record (so no autosave can write a record without the grant).
	local ok, status = core.save(player, { reason = "purchase", purchase = { id = purchaseId, grant = grant } })
	if not ok then
		return "retry"
	end
	if status == "liveAlready" then
		return "already"
	end
	return "granted"
end

return Purchases
