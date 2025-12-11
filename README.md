# ✅ Email Validation LWC Component

A Lightning Web Component for real-time email validation in Salesforce, powered by a free open-source API.

---

## 🎯 Business Problem

Salesforce orgs often suffer from **poor data quality** due to invalid or problematic email addresses:

- **Invalid emails** bounce, wasting marketing spend and hurting sender reputation
- **Disposable emails** (tempmail, guerrillamail) indicate low-quality leads
- **Typos** in common domains (gmial.com, yahooo.com) cause missed communications
- **Role-based emails** (info@, support@) often aren't monitored by individuals
- **Non-existent domains** waste sales rep time on unreachable contacts

---

## 💡 The Solution

A **real-time email validation component** that integrates directly into Salesforce, allowing users to validate emails before saving records. The component provides:

- ✅ **Instant validation** - Results in under 2 seconds
- 📊 **Quality score** - 0-100 score for email reliability
- 🔍 **6 validation checks** - Comprehensive analysis
- 🎨 **Visual feedback** - Color-coded results for quick understanding
- 🆓 **Free API** - No licensing costs, unlimited requests

### Validation Checks Performed

| Check | Description |
|-------|-------------|
| **Format Valid** | Email follows proper syntax (user@domain.com) |
| **Domain Exists** | The domain actually exists on the internet |
| **MX Record** | Domain has mail servers configured to receive email |
| **Mailbox Exists** | The specific mailbox/inbox exists |
| **Disposable** | Detects temporary/throwaway email services |
| **Role-Based** | Identifies generic emails like info@, support@, admin@ |


### Tech Stack

- **Frontend:** Lightning Web Component (LWC)
- **Backend:** Apex Controller with HTTP Callout
- **API:** [Rapid Email Verifier](https://rapid-email-verifier.fly.dev) (free, open-source)
- **Styling:** SLDS (Salesforce Lightning Design System)

### Key Features Implemented

1. **Real-time validation** on button click or Enter key
2. **Score display** (0-100) for quick quality assessment
3. **Status badges** (VALID, INVALID_FORMAT, INVALID_DOMAIN)
4. **6 individual validation cards** with pass/fail indicators
5. **Custom branding** with company logo
6. **Error handling** with user-friendly messages
7. **Loading states** for better UX


---

## 🔧 Setup Instructions

### 1. Add Remote Site Setting

Before deploying, configure the callout in Salesforce:

1. Go to **Setup → Remote Site Settings → New**
2. **Name:** `RapidEmailVerifier`
3. **URL:** `https://rapid-email-verifier.fly.dev`
4. **Active:** ✅ Checked

---
 
### Status Values

| Status | Meaning |
|--------|---------|
| `VALID` | Email is fully valid and deliverable |
| `INVALID_FORMAT` | Email syntax is incorrect |
| `INVALID_DOMAIN` | Domain doesn't exist or can't receive mail |

---

## 🔗 Resources

- **API Documentation:** [rapid-email-verifier.fly.dev](https://rapid-email-verifier.fly.dev)

---

## 📝 Lessons Learned

1. **API Response Mapping** - The API returns nested data (`validations` object), requiring careful parsing in Apex
2. **Status vs Individual Checks** - Using the `status` field for overall validity is more reliable than checking individual fields
3. **MX Records** - Understanding what MX (Mail Exchanger) records are helps explain validation results to users
4. **Remote Site vs Named Credentials** - Remote Site Settings work well for simple, unauthenticated APIs



