class AddStatusToIntegrations < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE TYPE integration_status AS ENUM ('pending', 'active', 'cancelled', 'failed', 'unauthorized');
    SQL
    add_column :integrations, :status, :integration_status, default: 'pending', null: false
    add_index :integrations, :status
  end

  def down
    remove_column :integrations, :status
    execute <<-SQL
      DROP TYPE integration_status;
    SQL
  end
end
