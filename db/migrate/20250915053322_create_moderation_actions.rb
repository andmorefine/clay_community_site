class CreateModerationActions < ActiveRecord::Migration[8.0]
  def change
    create_table :moderation_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.string :action_type
      t.text :reason
      t.references :target, polymorphic: true, null: false
      t.datetime :expires_at

      t.timestamps
    end
    
    add_index :moderation_actions, [:target_type, :target_id]
    add_index :moderation_actions, :action_type
    add_index :moderation_actions, :created_at
  end
end
