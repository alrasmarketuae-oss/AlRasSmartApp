# Al Ras Market — RAG knowledge base (v1 planning)

## Guest (visitor)
- Can browse banners, service types, categories, and products like a company home feed.
- Bottom bar can show My Orders / Create / Account / Profile entry points.
- Any action that requires auth redirects to login.

## Account types (summary)
- **Supplier**: full create ads (category/retail/booking/offers/requests), My Ads + My Offers, Balance, COD + Retail online rules.
- **Personal customer**: Google/Apple signup, home = Retail only, tabs: Home / My Orders / Profile, no create-ad, no balance.
- **Company customer**: home = category products (not retail-only), can create **Request** ads only, Account shows requests + offers, no balance.
- **Shipping company**: Home + Profile focused on shipping ads (ports, days, 20ft/40ft prices).

## Payments
- Online card payment: **Retail only**.
- Cash on delivery: applies to other deal flows via platform/Al Ras team process.
- Supplier balance increases immediately on Retail card payment.
- COD/retail-on-delivery: balance increases only after collection/receipt confirmation.
- Handing goods to the Al Ras app/team is not payment: supplier funds are released only after the buyer/customer payment is actually collected.
- Approved return: deduct supplier balance if previously credited.

## Returns
- Report within **24 business hours** of receipt with media evidence.
- Accepted typically: spoiled/damaged, expired vs listing, material mismatch, quantity shortage.
- If support approves: refund within **1 business day**.
- Supplier payouts/earnings transfer: within **7 business days**.

## Support channels (separate)
- **Live Chat**: human support agent session (Profile / Help).
- **AI Assistant**: knowledge Q&A FAB on Home (+ Help). Not the same as Live Chat.
- Unsupported languages: translate internally via OpenAI when needed; reply in AR/EN only.
- Greetings / out-of-scope: short guided reply, no RAG needed.

## Image search model
- Uses published product images (platform-owned after publish per Terms).
- Embedding + vector index (Qdrant) for similarity search.
- See in-app `ModelTrainingView` / LandingWebsite model-training page.

## Privacy & Terms source
- Mobile: Profile → Policy & Privacy (`TermsAndConditionsWidget`).
- Website: LandingWebsite `terms.js` + `modelTraining.js`.
