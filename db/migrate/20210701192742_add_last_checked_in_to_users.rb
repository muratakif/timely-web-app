# frozen_string_literal: true

class AddLastCheckedInToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :last_checked_in, :datetime
  end
end
