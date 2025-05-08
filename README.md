
### ✅ `README.md` (Redacted)

# discourse-send-sms-for-review

A Discourse plugin that sends an SMS via the OpenPhone API when a new post enters the moderation queue (i.e. flagged for review).

---

## ✅ Features

- Sends SMS alerts only for posts requiring approval (`Reviewable.exists?`)
- Uses the OpenPhone Messages API (`POST /v1/messages`)
- Reads configuration from `/shared/rails-env/.config.yml`
- Logs all actions with UTC timestamps
- Fails silently and safely if anything goes wrong

---

## 📦 Installation

1. Clone the plugin into your Discourse container:

```bash
cd /var/discourse
git clone https://github.com/unixneo/discourse-send-sms-for-review.git plugins/discourse-send-sms-for-review
````

2. Edit your `containers/app.yml`:

Under `hooks.after_code`, add:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/unixneo/discourse-send-sms-for-review.git
```

Under `volumes`, add:

```yaml
volumes:
  - volume:
      host: /etc/rails-env/.config.yml
      guest: /shared/rails-env/.config.yml
```

3. Rebuild the container:

```bash
cd /var/discourse
./launcher rebuild app
```

---

## 🔧 Configuration

In `/shared/rails-env/.config.yml`, include:

```yaml
OPENPHONE_API: "your_api_key"
OPENPHONE_PHONE_NUMBER_ALERTS: "+1YOUR_ALERT_LINE"
OPENPHONE_PHONE_NUMBER: "+1YOUR_PERSONAL_NUMBER"
```

Then, in **Discourse Admin > Settings**, enable:

* `discourse_send_sms_for_review_enabled`

---

## 📝 Example Payload Sent

```json
{
  "from": "+1YOUR_ALERT_LINE",
  "to": ["+1YOUR_PERSONAL_NUMBER"],
  "content": "New post awaiting approval: Example topic title"
}
```

---

## 📋 Logging

Logs are written to:

```
/shared/log/rails/production.log
```

Example entries (timestamped):

```
[2025-05-07T11:26:00Z] [SMS-Review] post_created hook triggered
[2025-05-07T11:26:00Z] [SMS-Review] SMS sent: id=abc123, status=queued
```

---

## 🔐 OpenPhone API

* Endpoint: `POST https://api.openphone.com/v1/messages`
* Headers:

  * `Authorization: <API_KEY>` (no Bearer prefix)
  * `Content-Type: application/json`

---

## License

MIT
