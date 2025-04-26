class CreateDescriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :descriptions do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :position_display

      t.timestamps
    end
  end
end
