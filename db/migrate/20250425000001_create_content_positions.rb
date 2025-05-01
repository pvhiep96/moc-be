class CreateContentPositions < ActiveRecord::Migration[7.2]
  def change
    create_table :content_positions do |t|
      t.references :project, null: false, foreign_key: true
      t.references :positionable, polymorphic: true, null: false
      t.integer :position, null: false

      t.timestamps
      
      t.index [:project_id, :position], unique: true
      t.index [:positionable_type, :positionable_id], unique: true
    end
  end
end