class CreateProjectImages < ActiveRecord::Migration[7.2]
  def change
    create_table :project_images do |t|
      t.string :image_url, null: false
      t.references :project, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :project_images, [:project_id, :image_url], unique: true
  end
end 
