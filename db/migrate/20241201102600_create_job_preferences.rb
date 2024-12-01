class CreateJobPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :job_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :keywords, null: false, array: true, default: []
      t.string :locations, null: false, array: true, default: []

      t.timestamps
    end
  end
end
