class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reportable, polymorphic: true, null: false
      t.string :reason
      t.text :description
      t.integer :status
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end
    
    add_index :reports, [:reportable_type, :reportable_id]
    add_index :reports, :status
    add_index :reports, :created_at
  end
end
