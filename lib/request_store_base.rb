module RequestStore
  module Base
    def self.get key
      store[key]
    end

    def self.set key, value
      store[key] = value
    end

    def self.store
      defined?(RequestStore) ? RequestStore.store : Thread.current
    end
  end
end
