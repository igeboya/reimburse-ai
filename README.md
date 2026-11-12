# ReimburseAI — receipt in, real money out

An expense reimbursement agent built entirely in n8n. An employee uploads a photo of a receipt, a
vision model reads it, a deterministic policy engine decides, the employee's manager clicks one
link, and PayPal Payouts sends the money. No server, no database, no dashboard to host.

**Live demo:** https://bengss.app.n8n.cloud/webhook/reimburse-form

**Demo video (1:46):** https://youtu.be/9PpQwPTjqvs

---

## What it does

1. **Employee** opens the form, snaps a receipt, types their PayPal email.
2. **AI vision** (DeepSeek-V4.1-Flash, multimodal) extracts merchant, date, line items, total and
   currency, and returns a JSON verdict against the company policy.
3. **Hard guardrails** re-check the same numbers in code: category limits, 30-day window, IDR only,
   readable fields, duplicate receipts. The model is never the only thing guarding the money.
4. **Manager approval**: the pending page carries a reference + random token. Opening the link shows
   the claim; clicking "Approve and pay" converts IDR → USD and calls PayPal Payouts.
5. **Money moves**: a PayPal payout batch is created, the batch id is shown on a paid page, and the
   claim is marked paid so the link cannot be replayed.

## Why it is not a toy

| Guardrail | What it prevents |
|---|---|
| Deterministic checks after the AI | a hallucinated "approve" never moves money on its own |
| Per-category limits (meal 150k, transport 100k, supplies 300k, other 100k IDR) | one bad read emptying the balance |
| 30-day / future-date window, computed in code against today | stale or pre-dated receipts |
| Duplicate hash `merchant\|date\|total\|email` | the same receipt submitted twice |
| Tokenised approval link, single use | replaying a payment link |
| Graceful `409 / 404` pages | users seeing raw `{"message":"Error in workflow"}` |

## Verified sandbox runs

| Claim | Receipt | Result |
|---|---|---|
| `MWCNU71YQVIH` | Toko ATK, Rp 96.000, supplies | paid — batch `RF5QAZYCK3URA`, PayPal `SUCCESS`, 6.00 USD |
| `MWCNM8QZNZ2K` | Kopi Kenangan, Rp 79.200, meal | paid — batch `6W46Z77XMYCL6`, `SUCCESS` |
| `MWCML543V10D` | Toko ATK, Rp 96.000 | paid — batch `QUMA789A5X2DU`, `SUCCESS` |
| `MWCN00DCACFG` | Steak 21, Rp 214.500, meal | rejected — exceeds the 150.000 IDR meal limit |
| replay of a paid link | — | `409` "This claim has already been paid", no second payout |

Payouts land in a second, separate sandbox account (`...@personal.example.com`); PayPal refuses
paying the sender's own account, which is why the receiver must be a different account.

## Architecture

Four independent webhook chains in one workflow (28 nodes):

```
GET  /webhook/reimburse-form     → form page (HTML served by n8n)
POST /webhook/reimburse          → Normalize → AI vision → Policy & Decision → pending / rejected page
GET  /webhook/reimburse-approve  → approval page (ref + token)
POST /webhook/reimburse-pay      → PayPal Payouts → paid page
```

State lives in `$getWorkflowStaticData('global')`: pending claims keyed by `ref`, plus a `seen` map
for duplicate receipts. No external database, and the workflow survives between executions.

## Setup

1. Import [`workflow/reimburse-ai.json`](workflow/reimburse-ai.json) into n8n.
2. Create two credentials and attach them:
   - **Header Auth** — `Authorization: Bearer <your model API key>` on `AI Vision - Read & Judge`
     (any OpenAI-compatible vision endpoint; this build uses `https://api.deepseek.com/v1`,
     model `deepseek-flash`).
   - **OAuth2 API** — grant type `Client Credentials`, access token URL
     `https://api-m.sandbox.paypal.com/v1/oauth2/token`, Authentication `Header`, with a sandbox app
     that has the **Payouts** capability.
3. Publish. The form is at `https://<your-subdomain>.app.n8n.cloud/webhook/reimburse-form`.
4. Submit a receipt whose PayPal email is **not** the app owner's account.

## Repo layout

```
workflow/reimburse-ai.json   importable n8n workflow (28 nodes)
docs/                        screenshots and the demo script
SUBMISSION.md                Devpost copy
LICENSE                      MIT
```

## Built with

n8n (self-hosted canvas on n8n.cloud) · DeepSeek-V4.1-Flash (vision) · PayPal Payouts API (sandbox) ·
JavaScript in Code nodes · HTML/CSS served straight from `respondToWebhook`.

## Known limitations

- A payout batch is created as `PENDING`; the paid page shows that status and the claim is marked
  paid on a `200`. A stricter build polls `GET /v1/payments/payouts/<id>` until `SUCCESS` before
  flipping the record.
- The IDR→USD rate is a constant (`16000`), not a live FX rate.
- Static data resets when the workflow is re-imported, which expires pending approval links.
