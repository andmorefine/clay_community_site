class CreateAppeals < ActiveRecord::Migration[8.0]
  def change
    create_table :appeals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :moderation_action, null: false, foreign_key: true
      t.text :reason
      t.integer :status
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end
    
    add_index :appeals, :status
    add_index :appeals, :created_at
  end
end
