class CreateChapters < ActiveRecord::Migration[6.1]
  def change
    create_table :chapters do |t|
      t.string :name, null: false
      t.integer :course_id, null: false
      t.float :ordering, null: false

      t.timestamps
    end
    add_foreign_key :chapters, :courses, on_delete: :cascade
  end
end
