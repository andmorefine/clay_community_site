class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false, limit: 100
      t.text :description, null: false, limit: 2000
      t.integer :post_type, default: 0
      t.integer :difficulty_level
      t.boolean :published, default: true

      t.timestamps
    end
    
    add_index :posts, :post_type
    add_index :posts, :published
    add_index :posts, :created_at
    add_index :posts, [:user_id, :created_at]
  end
end
