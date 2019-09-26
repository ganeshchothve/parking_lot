module Tasks
  def map_tasks
    task_hash = tasks.pluck(:key, :name, :order).inject({}) {|hsh, arr| hsh[arr[0]] = {name: arr[1], order: arr[2]}; hsh}
    current_client.checklists.each do |checklist|
      if task_hash.keys.include?(checklist.key)
        tasks.find_by(key: checklist.key).set(name: checklist.name) if task_hash[checklist.key][:name] != checklist.name
        tasks.find_by(key: checklist.key).set(order: checklist.order) if task_hash[checklist.key][:order] != checklist.order

      else
        tasks << Task.new(name: checklist.name, key: checklist.key, tracked_by: checklist.tracked_by, order: checklist.order)
      end
    end
  end
end