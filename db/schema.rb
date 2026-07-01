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

ActiveRecord::Schema[8.1].define(version: 2026_06_30_235826) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.string "size"
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "session_token"
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_carts_on_session_token"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["product_id"], name: "index_favorites_on_product_id"
    t.index ["user_id", "product_id"], name: "index_favorites_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "offers", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "buyer_id", null: false
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_offers_on_buyer_id"
    t.index ["product_id"], name: "index_offers_on_product_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.integer "order_id", null: false
    t.integer "price_cents", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.string "size"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_name"
    t.string "customer_phone"
    t.string "payment_id"
    t.string "payment_method"
    t.text "payment_pix_copia_cola"
    t.text "payment_pix_qr_code"
    t.integer "seller_id"
    t.text "shipping_address"
    t.string "shipping_cep"
    t.integer "shipping_cost_cents", default: 0, null: false
    t.string "shipping_method"
    t.string "shipping_status", default: "pending_shipment"
    t.string "status", default: "pending", null: false
    t.integer "total_cents", null: false
    t.string "tracking_code"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["seller_id"], name: "index_orders_on_seller_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payouts", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "pix_key", null: false
    t.string "pix_key_type", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_payouts_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "brand"
    t.string "category", null: false
    t.string "colors"
    t.string "condition"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "price_cents", null: false
    t.integer "price_promo_cents"
    t.string "sizes"
    t.integer "stock", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "answer"
    t.datetime "answered_at"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["product_id"], name: "index_questions_on_product_id"
    t.index ["user_id"], name: "index_questions_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "buyer_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "order_id", null: false
    t.integer "rating", null: false
    t.integer "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_reviews_on_buyer_id"
    t.index ["order_id"], name: "index_reviews_on_order_id", unique: true
    t.index ["seller_id"], name: "index_reviews_on_seller_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "address_city"
    t.string "address_complement"
    t.string "address_neighborhood"
    t.string "address_number"
    t.string "address_state"
    t.string "address_street"
    t.text "bio"
    t.string "cep"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "extra_ad_credits", default: 0, null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "buyer", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "favorites", "products"
  add_foreign_key "favorites", "users"
  add_foreign_key "offers", "products"
  add_foreign_key "offers", "users", column: "buyer_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "seller_id"
  add_foreign_key "payouts", "users"
  add_foreign_key "products", "users"
  add_foreign_key "questions", "products"
  add_foreign_key "questions", "users"
  add_foreign_key "reviews", "orders"
  add_foreign_key "reviews", "users", column: "buyer_id"
  add_foreign_key "reviews", "users", column: "seller_id"
  add_foreign_key "sessions", "users"
end
