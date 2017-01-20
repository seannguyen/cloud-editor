class CreateNoteUserJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_join_table :notes, :users do |t|
      # t.index [:note_id, :user_id]
      t.index [:user_id, :note_id], unique: true
    end
  end
end
