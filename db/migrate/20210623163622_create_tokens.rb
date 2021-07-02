# frozen_string_literal: true

class CreateTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :tokens do |t|
      t.string :content
      t.string :gcalendar_user_id, index: true
      t.timestamp :expires_at

      t.belongs_to :user, index: true
      t.timestamps
    end
  end
end
