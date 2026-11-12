# Demo video script — max 3:00, target 2:30

Recording settings: 1080p, browser zoom 100%, no copyrighted music, voiceover in English with
captions on screen. Upload to YouTube as **Public**.

Prepare before recording:
- Receipt image: `receipt7.png` (Toko ATK Cahaya, Rp 185.000, supplies, date 2026-11-12) — this one
  is not yet used with the demo PayPal email, so it will not trip duplicate detection.
- Second receipt for the rejection scene: `receipt6.png` (Steak 21, Rp 214.500 — over the 150.000 meal limit).
- Logged-in PayPal sandbox (developer.paypal.com → Testing Tools → Sandbox Accounts → the Personal
  account used as receiver), ready on the Activity tab.
- Tabs pre-opened: form, n8n canvas, PayPal sandbox activity.

---

## 0:00 – 0:15 · Hook

**Screen:** the claim form (`/webhook/reimburse-form`).

**Voice:** "Expense reports die between 'I paid for this' and 'someone approved it'. This is
ReimburseAI — a receipt becomes real money in under a minute, with no spreadsheet and no emails."

## 0:15 – 0:40 · Submit

**Screen:** click the file input, choose `receipt7.png`, type the PayPal email, submit.

**Voice:** "An employee uploads a photo of the receipt and their PayPal email. That's the entire
input."

## 0:40 – 1:05 · The AI + the policy engine

**Screen:** the pending page — merchant, date, category, line items, receipt total, payout amount.

**Voice:** "A vision model reads the receipt — merchant, date, every line item, total, currency.
Then deterministic code re-checks the same numbers: category limits, a thirty-day window, IDR only,
duplicate submissions. The model proposes; the code decides what is allowed to move money."

## 1:05 – 1:30 · Manager approval

**Screen:** click "Manager approval page" → the approval page → click "Approve and pay 11.56 USD".

**Voice:** "The claim is held behind a tokenised link. The manager sees exactly what the employee
claimed, the policy verdict, and the dollar amount. One click pays it."

## 1:30 – 1:55 · Money moves

**Screen:** the paid page — amount, recipient, **payout batch id** highlighted.

**Voice:** "PayPal Payouts sends the money and returns a batch id. No manual transfer, no waiting for
finance."

## 1:55 – 2:20 · Proof it is real

**Screen:** PayPal sandbox → payouts batch → status **SUCCESS**; then the receiving account's
Activity showing the incoming payment.

**Voice:** "This is the same batch, verified in the PayPal sandbox: status SUCCESS, funds in the
employee's account. Not a mockup — a real payout call."

## 2:20 – 2:40 · Guardrails

**Screen:** reopen the same approval link → the `409` page "This claim has already been paid". Then
submit `receipt6.png` → the rejected page with "exceeds the meal limit of Rp 150.000".

**Voice:** "The link cannot be replayed, and a receipt over the limit is refused with a reason the
employee can act on."

## 2:40 – 2:55 · How it is built

**Screen:** the n8n canvas (28 nodes, four webhook chains), then the GitHub repo page.

**Voice:** "One n8n workflow — form, vision, policy, approval and payout — no server, no database.
Code and workflow JSON are in the repository below."

---

## Notes for editing

- Keep the cursor movements slow; judges skim.
- Freeze-frame the batch id for at least 2 seconds — it is the strongest single proof.
- Title card (first frame): "ReimburseAI — receipt in, money out".
- End card: repo URL + live demo URL.
