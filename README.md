### 📄 `README.md`

# discourse-send-sms-for-review

A Discourse plugin that sends an SMS via OpenPhone when a new post enters the moderation review queue (requires approval).

## Features

- Sends SMS notifications using OpenPhone API
- Reads API key, phone IDs, and numbers from `/etc/rails-env/.config.yml`
- Fails silently on error — does not interfere with Discourse operations
- Optional logging via site setting

## Installation

Clone into your Discourse plugin directory:

```bash
cd /var/discourse/plugins
git clone https://github.com/YOUR_USERNAME/discourse-send-sms-for-review.git
````

Then rebuild or restart your app:

```bash
cd /var/discourse
./launcher restart app
```

## Configuration

Add the following site setting in Admin > Settings:

* `discourse_send_sms_for_review_enabled`: Enable or disable SMS notifications
* `discourse_send_sms_for_review_logging_enabled`: Enable or disable plugin logging

Edit `/etc/rails-env/.config.yml` with the following required keys:

```yaml
OPENPHONE_API: "your_api_key"
OPENPHONE_PHONE_NUMBER: "+1xxxxxxxxxx"
```

## License

MIT

