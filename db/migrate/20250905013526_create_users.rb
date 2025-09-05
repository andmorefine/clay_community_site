class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 255
      t.string :username, null: false, limit: 50
      t.string :password_digest, null: false
      t.text :bio
      t.string :skill_level, default: 'beginner', limit: 20

      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
  end
end
