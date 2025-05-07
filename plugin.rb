# name: discourse-send-sms-for-review
# about: Send SMS via OpenPhone when posts require approval
# version: 0.3
# authors: unix.com
# url: https://unix.com

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
    next unless SiteSetting.discourse_send_sms_for_review_enabled
    next unless post.needs_approval?

    begin
      config_path = "/etc/rails-env/.config.yml"
      unless File.exist?(config_path)
        Rails.logger.warn("[SMS-Review] Config file not found") if SiteSetting.discourse_send_sms_for_review_logging_enabled
        next
      end

      config = YAML.load_file(config_path)
      api_key     = config['OPENPHONE_API']
      from_number = config['OPENPHONE_PHONE_NUMBER']
      to_number   = config['OPENPHONE_PHONE_NUMBER']

      if api_key.blank? || from_number.blank? || to_number.blank?
        Rails.logger.warn("[SMS-Review] Missing config keys") if SiteSetting.discourse_send_sms_for_review_logging_enabled
        next
      end

      payload = {
        content: "New post awaiting approval: #{post.topic.title}",
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

      if response.code == 202
        body = JSON.parse(response.body) rescue nil
        if body && body["messageId"]
          Rails.logger.info("[SMS-Review] SMS sent successfully: ID #{body["messageId"]}") if SiteSetting.discourse_send_sms_for_review_logging_enabled
        else
          Rails.logger.warn("[SMS-Review] SMS 202 but no messageId returned") if SiteSetting.discourse_send_sms_for_review_logging_enabled
        end
      else
        Rails.logger.warn("[SMS-Review] SMS failed (#{response.code}): #{response.body}") if SiteSetting.discourse_send_sms_for_review_logging_enabled
      end

    rescue => e
      Rails.logger.error("[SMS-Review] Exception: #{e.message}") if SiteSetting.discourse_send_sms_for_review_logging_enabled
    end
  end
end

