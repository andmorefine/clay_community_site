class AddEmailVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_verified, :boolean, default: false, null: false
    add_column :users, :email_verified_at, :datetime
    add_index :users, :email_verified
  end
end
