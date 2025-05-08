### ✅ `README.md`

# discourse-send-sms-for-review

A Discourse plugin that sends an SMS via the OpenPhone API when a newly created post is immediately placed into the moderation review queue.

This plugin is intended for low-traffic sites where urgent moderation review is important and SMS alerts should be rare but actionable.

---

## ✅ What It Actually Does

- Listens for `:post_created` events from Discourse
- Checks if a `Reviewable` record exists **at the moment the post is created**
- If so, sends an SMS via OpenPhone with the topic title
- Logs all decisions and actions with ISO 8601 UTC timestamps
- Fails silently on all errors (no user interruption)

---

## ⚙️ Requirements

- A working [OpenPhone](https://www.openphone.com) account with SMS-enabled number(s)
- A local YAML config at `/etc/rails-env/.config.yml` containing your API key and phone numbers
- That config file must be **mounted** into the container at `/shared/rails-env/.config.yml`

---

## 🛠️ Installation

1. Clone the plugin into your Discourse instance:

```bash
cd /var/discourse
git clone https://github.com/unixneo/discourse-send-sms-for-review.git plugins/discourse-send-sms-for-review
````

2. Edit `containers/app.yml`:

Under `hooks.after_code`, add:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/unixneo/discourse-send-sms-for-review.git
```

Under `volumes`, add the following:

```yaml
volumes:
  - volume:
      host: /etc/rails-env/.config.yml
      guest: /shared/rails-env/.config.yml
```

3. Rebuild your container:

```bash
cd /var/discourse
./launcher rebuild app
```

---

## 🔧 Configuration

Create or edit this file on the host machine:

```yaml
# /etc/rails-env/.config.yml

OPENPHONE_API: "your_api_key"
OPENPHONE_PHONE_NUMBER_ALERTS: "+1YOUR_SENDER_NUMBER"
OPENPHONE_PHONE_NUMBER: "+1YOUR_DESTINATION_NUMBER"
```

Then inside Discourse, enable the plugin in:

```
Admin > Settings > discourse_send_sms_for_review_enabled
```

---

## 📨 SMS Payload Example

```json
{
  "from": "+1YOUR_SENDER_NUMBER",
  "to": ["+1YOUR_DESTINATION_NUMBER"],
  "content": "New post awaiting approval: How to reset root password"
}
```

---

## 📋 Logging

All actions are logged to:

```
/shared/log/rails/production.log
```

Example entries:

```
[2025-05-08T10:14:47Z] [SMS-Review] post_created hook triggered
[2025-05-08T10:14:47Z] [SMS-Review] Sending SMS payload: {...}
[2025-05-08T10:14:47Z] [SMS-Review] OpenPhone response: HTTP 202
[2025-05-08T10:14:47Z] [SMS-Review] SMS sent: id=AC123..., status=delivered
```

---

## ❗ Important Behavior Notes

* If the post is added to the review queue **after** creation (e.g., flagged later), no SMS will be sent.
* The plugin only reacts at post creation time and checks if it's already reviewable.
* To simulate review conditions for testing, see console examples in plugin documentation or issue a `DiscourseEvent.trigger(:post_created, post)` manually.

---

## License

MIT
