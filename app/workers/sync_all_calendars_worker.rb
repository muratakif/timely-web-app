# frozen_string_literal: true

class SyncAllCalendarsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: 3

  def perform(user_id)
    User.where(has_synced: false).each do |user|
      SyncCalendarWorker.perform_async(user.id)
    end 
  end
end
