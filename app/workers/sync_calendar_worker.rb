# frozen_string_literal: true

class SyncCalendarWorker
  include Sidekiq::Worker
  sidekiq_options queue: :calendar_setup, retry: 3

  def perform(user_id)
    last_checked_in = Event.find_by(user_id: user_id, order: 'starts_at DESC')&.starts_at # TODO: add last_checked_in column to users and query through there
    service = Events::Sync.new(user_id, from)
    service.call
  end
end
