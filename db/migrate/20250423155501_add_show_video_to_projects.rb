class AddShowVideoToProjects < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :show_video, :boolean
  end
end
