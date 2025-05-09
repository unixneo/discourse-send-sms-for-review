### ✅ `README.md` (v0.8.0)

# discourse-send-sms-for-review

A Discourse plugin that sends an SMS via the OpenPhone API when a newly created post is immediately placed into the moderation review queue.

Designed for low-traffic sites where urgent moderation needs can justify SMS alerts, but with strict time gating to avoid noise and overnight interruptions.

---

## ✅ Features

- Listens for `:post_created` events
- Checks if the post is immediately associated with a `Reviewable` (e.g., queued post, flagged post)
- Sends an SMS via OpenPhone with the topic title
- Supports local time windows (e.g., only alert between 08:00 and 21:00)
- Time zone fully configurable using IANA zone names (e.g., `Asia/Bangkok`)
- All behavior and logging controlled via admin settings
- Fails silently and logs clearly

---

## 📦 Installation

1. Clone into your Discourse container:

```bash
cd /var/discourse
git clone https://github.com/unixneo/discourse-send-sms-for-review.git plugins/discourse-send-sms-for-review
````

2. In `containers/app.yml`:

Under `hooks.after_code`:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/unixneo/discourse-send-sms-for-review.git
```

Under `volumes`:

```yaml
volumes:
  - volume:
      host: /etc/rails-env/.config.yml
      guest: /shared/rails-env/.config.yml
```

3. Rebuild Discourse:

```bash
./launcher rebuild app
```

---

## 🔧 Configuration

### In `/etc/rails-env/.config.yml`:

```yaml
OPENPHONE_API: "your_api_key"
OPENPHONE_PHONE_NUMBER_ALERTS: "+1YOUR_SENDER"
OPENPHONE_PHONE_NUMBER: "+1YOUR_DESTINATION"
```

### In Discourse Admin > Settings:

* `discourse_send_sms_for_review_enabled`: Enable/disable plugin
* `discourse_send_sms_for_review_logging_enabled`: Enable/disable logging
* `discourse_send_sms_for_review_start_hour`: Start of allowed SMS window (local hour, 0–23)
* `discourse_send_sms_for_review_end_hour`: End of allowed SMS window (local hour, 0–23)
* `discourse_send_sms_for_review_timezone`: IANA time zone name (e.g., `Asia/Bangkok`, `UTC`, `America/New_York`)

---

## 📨 Example Payload Sent

```json
{
  "from": "+1YOUR_SENDER",
  "to": ["+1YOUR_DESTINATION"],
  "content": "New post awaiting approval: Test topic"
}
```

---

## 📋 Logging

Logs go to:

```
/shared/log/rails/production.log
```

Examples:

```
[2025-05-08 10:14:47 +0000] [SMS-Review] post_created hook triggered
[2025-05-08 10:14:47 +0000] [SMS-Review] SMS suppressed due to time window: 02:14 not in 8:00–21:59 (Asia/Bangkok)
```

---

## 🔐 API

* OpenPhone API endpoint: `POST https://api.openphone.com/v1/messages`
* Headers:

  * `Authorization: <API_KEY>` (no Bearer prefix)
  * `Content-Type: application/json`

---

## License

MIT
