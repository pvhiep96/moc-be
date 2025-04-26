# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_04_23_155501) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "user_name"
    t.string "password_digest"
    t.string "fullname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "descriptions", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "position_display"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content"
    t.index ["project_id"], name: "index_descriptions_on_project_id"
  end

  create_table "project_images", force: :cascade do |t|
    t.string "image_url", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "image_url"], name: "index_project_images_on_project_id_and_image_url", unique: true
    t.index ["project_id"], name: "index_project_images_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.string "drive_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_video"
  end

  create_table "video_urls", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_video_urls_on_project_id"
  end

  add_foreign_key "descriptions", "projects"
  add_foreign_key "project_images", "projects"
  add_foreign_key "video_urls", "projects"
end
