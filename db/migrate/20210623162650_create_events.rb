# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.string :name
      t.string :description
      t.boolean :recurring
      t.time :starts_at
      t.time :ends_at
      t.string :gcalendar_id, index: true

      t.belongs_to :user, index: true
      t.timestamps
    end
  end
end
