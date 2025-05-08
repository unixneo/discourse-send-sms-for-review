# name: discourse-send-sms-for-review
# about: Send SMS via OpenPhone when posts are flagged for approval
# version: 0.7.1
# authors: unix.com
# url: https://github.com/unixneo/discourse-send-sms-for-review

require 'yaml'
require 'httparty'
require 'time'

enabled_site_setting :discourse_send_sms_for_review_enabled

after_initialize do
  module ::DiscourseSendSmsForReview
    class Engine < ::Rails::Engine
      engine_name "discourse_send_sms_for_review"
      isolate_namespace DiscourseSendSmsForReview
    end
  end

  def log_sms(level, msg)
    timestamp = Time.now.utc.iso8601
    Rails.logger.send(level, "[#{timestamp}] [SMS-Review] #{msg}")
  end

  DiscourseEvent.on(:post_created) do |post|
    begin
      log_sms(:info, "post_created hook triggered")

      unless SiteSetting.discourse_send_sms_for_review_enabled
        log_sms(:info, "Plugin disabled via site setting")
        next
      end

      unless post.is_a?(Post)
        log_sms(:warn, "Unexpected object in post_created event")
        next
      end

      unless Reviewable.exists?(target: post)
        log_sms(:info, "No Reviewable found for post_id=#{post.id}")
        next
      end

      config_path = "/shared/rails-env/.config.yml"
      unless File.exist?(config_path)
        log_sms(:error, "Config path not found: #{config_path}")
        next
      end

      config = YAML.load_file(config_path)
      api_key     = config['OPENPHONE_API']
      from_number = config['OPENPHONE_PHONE_NUMBER_ALERTS']
      to_number   = config['OPENPHONE_PHONE_NUMBER']

      if api_key.blank? || from_number.blank? || to_number.blank?
        log_sms(:error, "Missing required config keys (api_key? #{api_key.present?})")
        next
      end

      title = post.topic&.title || "Untitled Topic"
      message_text = "New post awaiting approval: #{title}"

      payload = {
        from: from_number,
        to: [to_number],
        content: message_text
      }

      log_sms(:info, "Sending SMS payload: #{payload.inspect}")

      response = HTTParty.post(
        "https://api.openphone.com/v1/messages",
        headers: {
          "Authorization" => api_key,
          "Content-Type" => "application/json"
        },
        body: payload.to_json
      )

      log_sms(:info, "OpenPhone response: HTTP #{response.code}")

      if response.code == 202
        body = JSON.parse(response.body) rescue {}
        data = body["data"]
        if data && data["id"] && data["status"]
          log_sms(:info, "SMS sent: id=#{data["id"]}, status=#{data["status"]}")
        else
          log_sms(:warn, "202 response missing 'data.id' or 'data.status'")
        end
      else
        log_sms(:warn, "Failed to send SMS: #{response.code} #{response.body}")
      end

    rescue => e
      log_sms(:error, "Uncaught Exception: #{e.message}")
      log_sms(:error, e.backtrace.join("\n"))
    end
  end
end
