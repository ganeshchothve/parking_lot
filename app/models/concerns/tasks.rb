module Tasks
  extend ActiveSupport::Concern

  included do
    Checklist::TRACKED_BY.each do |tracked_by|
      field "#{tracked_by}_tasks_completed".to_sym, type: Boolean, default: false
    end

    before_save do |booking_detail|
      Checklist::TRACKED_BY.each do |tracked_by|
        booking_detail.send("#{tracked_by}_tasks_completed=", ( booking_detail.tasks.blank? || booking_detail.tasks.where(tracked_by: tracked_by).all?(&:completed?) ))
      end
    end
  end

  def map_tasks
    task_hash = tasks.pluck(:key, :name, :order).inject({}) {|hsh, arr| hsh[arr[0]] = {name: arr[1], order: arr[2]}; hsh}
    current_client.checklists.each do |checklist|
      if task_hash.keys.include?(checklist.key)
        tasks.find_by(key: checklist.key).set(name: checklist.name, order: checklist.order) if task_hash[checklist.key][:name] != checklist.name || task_hash[checklist.key][:order] != checklist.order
      else
        tasks << Task.new(name: checklist.name, key: checklist.key, tracked_by: checklist.tracked_by, order: checklist.order)
      end
    end
  end
end
