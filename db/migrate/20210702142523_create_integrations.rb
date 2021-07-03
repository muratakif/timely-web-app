class CreateIntegrations < ActiveRecord::Migration[6.1]
  def change
    create_table :integrations do |t|
      t.string :name, null: false
      t.string :sync_token
      t.datetime :last_synced

      t.belongs_to :user, index: true
      t.timestamps
    end
  end
end
