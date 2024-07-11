class CreateUnits < ActiveRecord::Migration[6.1]
  def change
    create_table :units do |t|
      t.string :name, null: false
      t.string :description
      t.string :content, null: false
      t.float :ordering, null: false
      t.integer :chapter_id, null: false

      t.timestamps
    end
    add_foreign_key :units, :chapters, on_delete: :cascade
  end
end
