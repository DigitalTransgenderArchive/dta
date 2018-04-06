class ChangeBaseFilesIndex < ActiveRecord::Migration[5.2]
  def change
    # Will Need to Change This
    if index_exists? :base_files, [:parent_pid, :sha256]
      remove_index :base_files, [:parent_pid, :sha256]
    end
  end
end
