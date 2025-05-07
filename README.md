### ✅ `README.md`

# discourse-send-sms-for-review

A Discourse plugin that sends an SMS via the OpenPhone API when a new post enters the moderation queue for approval.

## ✅ Features

- Sends SMS alerts only for posts requiring approval (based on Reviewable presence)
- Integrates with OpenPhone API (v1/messages)
- Reads secrets and numbers from `/shared/rails-env/.config.yml`
- Uses proper OpenPhone API structure, headers, and response fields (`data.id`, `data.status`)
- Fails silently and logs detailed information to `production.log`

---

## 📦 Installation

1. Clone into your Discourse container's plugin directory:

```bash
cd /var/discourse
git clone https://github.com/unixneo/discourse-send-sms-for-review.git plugins/discourse-send-sms-for-review
````

2. Edit `containers/app.yml` and add to `hooks.after_code`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/unixneo/discourse-send-sms-for-review.git
```

3. Rebuild Discourse:

```bash
./launcher rebuild app
```

---

## 🔧 Configuration

In Discourse Admin Panel > Settings:

* Enable: `discourse_send_sms_for_review_enabled`

Update `/shared/rails-env/.config.yml` with required values:

```yaml
OPENPHONE_API: "your_api_key"
OPENPHONE_PHONE_NUMBER_ALERTS: "+16503189610"
OPENPHONE_PHONE_NUMBER: "+17035368985"
```

---

## 📋 Example SMS Sent

```json
{
  "content": "New post awaiting approval: How to reset root password",
  "from": "+16503889610",
  "to": ["+17035318965"]
}
```

---

## 📝 Logging

Logs appear in:

```
/shared/log/rails/production.log
```

Log tags include `[SMS-Review]` and cover all stages of processing.

---

## 🔐 API Used

* OpenPhone Messages API: `POST /v1/messages`
* Headers:

  * `Authorization: <api_key>` (no Bearer prefix)
  * `Content-Type: application/json`

---

## License

MIT

