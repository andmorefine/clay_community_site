class AddModerationFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: 'user'
    add_column :users, :suspended, :boolean, default: false
    add_column :users, :suspended_until, :datetime
    add_column :users, :warning_count, :integer, default: 0
    
    add_index :users, :role
    add_index :users, :suspended
  end
end
