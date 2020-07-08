module Amura
  class SidekiqManager

    # Details for server. it should contain below format. all keys in symbolic form.
    # => {
    #   redis: {
    #     url: <redis url if your are local then it will be "redis://127.0.0.1:6379" >,
    #     password: <if any else dont add this key>},
    #     workers: {
    #       <queue name in symbolic form>: {
    #         max: <max size of queue worker, datatype Integer.>,
    #         conc: < Datatype Integer, thread size>,
    #         queue_size: < Datatype Integer, where one thred can handle>,
    #         tag: <queue_name>
    #       }
    #     }
    #   }
    # }
    DETAILS = YAML.load_file("#{Rails.root}/config/sidekiq_manager.yml")

    # workers set
    WORKERS_SET = DETAILS[:workers] || {}

    # initialize rediss object.
    @@redis = Redis.new( ENV_CONFIG[:redis] )

    class << self
      # When need to restart the workers.
      def restart
        WORKERS_SET.each do |queue_name, queue_meta_data|
          # Quiet all running queues.
          Sidekiq::ProcessSet.new.each do |sps|
            if sps['queues'].include?(queue_name.to_s)
              sps.quiet!
            end
          end
          self.kill_quiet_ones
          # Start New queue.
          (1..queue_meta_data['min'].to_i).each do |tag|
            self.start_processs( tag, queue_name, queue_meta_data['conc'])
          end
        end
      end

      # In this function first calculate the max size of workers count
      # max count = (<current queue size> / < one worker max queue_size >).ceil
      # e.g => 1.1.ceil = 2
      # the current worker thread if its less than max add only those extra worker. else remove those extra worker.
      # also remove if some one has zero busy thread.
      def run
        self.kill_quiet_ones
        WORKERS_SET.each do |queue_name, queue_meta_data|
          queue_meta_data_info = self.default_queue_meta_data(queue_name).merge(queue_meta_data.symbolize_keys)

          queue = Sidekiq::Queue.new(queue_name.to_s)
          current_processes = Sidekiq::ProcessSet.new
          processes = current_processes.select{ |sps| sps['queues'].include?(queue_name.to_s) }

          current_working_tags = processes.collect{|x| x["tag"].gsub( queue_name.to_s,"").to_i }

          queue_size = (queue.size / queue_meta_data_info[:queue_size].to_f).ceil
          max_size   = ( queue_size > queue_meta_data_info[:max] ? queue_meta_data_info[:max].to_i : queue_size )

          puts "#{queue_name} = Max required queue_size #{ queue_size }"
          if queue_size.zero?
            processes.each_with_index do |x, index|
              # quiet every things when nothing is in scheduled
              # if !index.zero?
                if x["busy"].zero?
                  x.quiet!
                end # end If
              # end # end processes
            end
            #self.start_processs( 1, queue_name, queue_meta_data_info[:conc] ) if processes.blank?
          elsif max_size > current_working_tags.size
            # added new workers.
            ((1..max_size).to_a - current_working_tags).each do |tag|
              self.start_processs( tag, queue_name, queue_meta_data_info[:conc] )
            end
          else
            # remove extra working workers.
            (current_working_tags - (1..max_size).to_a).each do |tag|
              processes.each do |x|
                if x["tag"] == "#{queue_name}#{tag}"
                  puts "#{queue_name} = Stoping #{queue_name}#{tag}"
                  x.quiet!
                end # end If
              end # end processes
            end # end extra worker block.

          end # end else
        end
        self.kill_quiet_ones
      end

      # This function will kill all workers which set to quiet as true. means mark for destroy. and busy tread are zero.
      def kill_quiet_ones
        puts 'killing proccess'
        Sidekiq::ProcessSet.new.each do |x|
          if ( x["quiet"] == "true" && x["busy"].zero? )
            x.stop!
          end
        end
      end

      # This function start new procrss with given tag name, queue name, and thread size.
      def start_processs( tag, queue_name, conc=5)
        conc ||= 5
        pid = Process.spawn("bundle exec sidekiq -d -q #{queue_name} -c#{conc}  -e #{Rails.env} -L log/#{queue_name}_sidekiq.log -g #{queue_name}#{tag}")
        # Detach the spawned process
        Process.detach pid
      end

      # This defulat setting which is required for worker.
      def default_queue_meta_data(queue_name='default')
        { max: 1, conc: 5, queue_size: 500, tag: queue_name }
      end
    end
  end
end
