# Devpost submission text — ReimburseAI

## Short description (one sentence)

Snap a receipt and ReimburseAI reads it, applies your expense policy, gets one manager click, and
pays the employee through PayPal Payouts.

## Inspiration

Expense reports die in the gap between "I paid for this" and "someone approved it". The employee
forgets, the manager is busy, finance pays late, and the receipt lives in a chat thread. We wanted
the whole loop — read the paper, enforce the policy, approve, pay — to happen in under a minute
without anyone opening a spreadsheet.

## What it does

The employee uploads a photo of a receipt and their PayPal email. A multimodal model reads the
merchant, date, line items, total and currency, and returns a verdict against the company policy.
Deterministic code then re-checks the same numbers: category limits, a 30-day window, IDR only,
unreadable fields, and duplicate submissions. If the receipt passes, the employee gets a "waiting
for manager approval" page with a tokenised link; the manager sees the claim, its line items and the
USD payout, and one click converts IDR to USD and sends a **PayPal Payout**. The employee lands on a
paid page with the batch id. Replaying the link returns a `409` page that says the claim was already
paid — never a second payout, never a raw JSON error.

Rejections are explained, not just refused: *"exceeds the meal limit of Rp 150.000"*, *"receipt date
is in the future"*, *"this receipt was already submitted"*.

## How we built it

- **n8n as the whole backend.** Four webhook chains in one workflow: form, submit, approve, pay.
  The HTML pages are rendered from Code nodes and returned by `respondToWebhook` — no hosting.
- **Vision step.** `AI Vision - Read & Judge` is one HTTP Request node against an
  OpenAI-compatible chat endpoint (`deepseek-flash`, which accepts image input), with the receipt
  sent as a base64 data URL and a strict JSON schema in the system prompt.
- **Policy engine in code.** `Policy & Decision` takes the model's JSON and applies the limits the
  model cannot be trusted with, then computes the payout amount.
- **State without a database.** `$getWorkflowStaticData('global')` holds pending claims keyed by a
  short `ref` plus a random `token`, and a `seen` map for duplicate detection.
- **PayPal Payouts.** One OAuth2 client-credentials credential, one `POST /v1/payments/payouts`
  with a dynamically built body, and the batch id surfaced back to the user.

## Challenges

- **The model does not know today's date.** Every receipt dated 2026 came back "future-dated" and
  was rejected until we injected `TODAY:` into the prompt and told it to judge dates relative to
  that. Five different model ids failed the same way.
- **Explanations are not verdicts.** Our first gate treated the model's `policy_reasons` array as
  the rejection list, so a receipt the model *approved* with helpful notes was rejected — the page
  said "rejected" while listing only approving sentences. Notes had to move into their own field.
- **A `200` from PayPal is not money.** The batch is created as `PENDING`; a payout to the sender's
  own account is accepted, then flips to `DENIED` / `SELF_PAY_NOT_ALLOWED` seconds later. We had to
  poll the batch and use a second sandbox account as the receiver.
- **n8n's JSON body and expressions.** The payout body returned `400 MALFORMED_REQUEST_JSON` until it
  was built as a single `JSON.stringify(...)` expression instead of raw JSON with `{{ }}` inside.
- **Throwing is a UI decision.** A `throw` inside a loader node becomes `{"message":"Error in
  workflow"}` at status 500 in the user's browser. Re-clicking an approval link looked like the
  integration had crashed. Loaders now return `{ ok: false, reason }` and an IF routes to a light,
  human-readable page.

## What's next

Live FX rates, per-item category overrides, a manager dashboard listing pending claims instead of
one link per claim, Slack/WhatsApp delivery of approval links, a payout-status poller that only marks
a claim paid once PayPal reports `SUCCESS`, and multi-tenant policies per company.

## Built with

n8n, PayPal Payouts API (sandbox), PayPal OAuth2 client credentials, DeepSeek-V4.1-Flash vision
model, JavaScript, HTML/CSS.

## Tools section (what the form asks for)

| Tool | Role |
|------|------|
| PayPal Payouts API (sandbox) | sends one payout batch per approved claim and returns the batch id |
| PayPal OAuth2 (client credentials) | token acquisition for the payout call |
| DeepSeek-V4.1-Flash (vision) | multimodal receipt reading: merchant, date, items, total, currency |
| n8n | orchestration, HTTP calls, policy code, webhook endpoints, HTML pages, static state |
