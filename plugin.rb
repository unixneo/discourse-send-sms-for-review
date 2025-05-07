# name: discourse-send-sms-for-review
# about: Send SMS via OpenPhone when posts are flagged for approval
# version: 0.7
# authors: unix.com
# url: https://github.com/unixneo/discourse-send-sms-for-review

require 'yaml'
require 'httparty'

enabled_site_setting :discourse_send_sms_for_review_enabled

after_initialize do
  module ::DiscourseSendSmsForReview
    class Engine < ::Rails::Engine
      engine_name "discourse_send_sms_for_review"
      isolate_namespace DiscourseSendSmsForReview
    end
  end

  DiscourseEvent.on(:post_created) do |post|
    begin
      Rails.logger.info("[SMS-Review] post_created hook triggered")

      unless SiteSetting.discourse_send_sms_for_review_enabled
        Rails.logger.info("[SMS-Review] Plugin disabled via site setting")
        next
      end

      unless post.is_a?(Post)
        Rails.logger.warn("[SMS-Review] Unexpected object in post_created event")
        next
      end

      unless Reviewable.exists?(target: post)
        Rails.logger.info("[SMS-Review] No Reviewable found for post_id=#{post.id}")
        next
      end

      config_path = "/shared/rails-env/.config.yml"
      unless File.exist?(config_path)
        Rails.logger.error("[SMS-Review] Config path not found: #{config_path}")
        next
      end

      config = YAML.load_file(config_path)
      api_key     = config['OPENPHONE_API']
      from_number = config['OPENPHONE_PHONE_NUMBER_ALERTS']
      to_number   = config['OPENPHONE_PHONE_NUMBER']

      if api_key.blank? || from_number.blank? || to_number.blank?
        Rails.logger.error("[SMS-Review] Missing required config keys")
        next
      end

      title = post.topic&.title || "Untitled Topic"
      Rails.logger.info("[SMS-Review] Preparing payload for topic '#{title}'")

      payload = {
        content: "New post awaiting approval: #{title}",
        from: from_number,
        to: [to_number]
      }

      response = HTTParty.post(
        "https://api.openphone.com/v1/messages",
        headers: {
          "Authorization" => api_key,
          "Content-Type" => "application/json"
        },
        body: payload.to_json
      )

      Rails.logger.info("[SMS-Review] OpenPhone response: HTTP #{response.code}")

      if response.code == 202
        body = JSON.parse(response.body) rescue {}

        data = body["data"]
        if data && data["id"] && data["status"]
          Rails.logger.info("[SMS-Review] SMS sent: id=#{data["id"]}, status=#{data["status"]}")
        else
          Rails.logger.warn("[SMS-Review] 202 response missing 'data.id' or 'data.status'")
        end
      else
        Rails.logger.warn("[SMS-Review] Failed to send SMS: #{response.code} #{response.body}")
      end

    rescue => e
      Rails.logger.error("[SMS-Review] Uncaught Exception: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end

