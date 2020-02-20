module JsonUtil
  def self.filter(filter_hash, original_hash, is_table = false)
    filter_hash = filter_hash.with_indifferent_access
    original_hash = original_hash.with_indifferent_access
    hash_keys = original_hash.keys

    if only = filter_hash[:only]
      only = only.take(5) if is_table
      hash_keys &= Array(only).map(&:to_s)
    elsif except = filter_hash[:except]
      hash_keys -= Array(except).map(&:to_s)
      hash_keys = hash_keys.take(5) if is_table
    end

    hash = {}
    hash_keys.each { |n| hash[n] = (original_hash[n].is_a?(Array) ? original_hash[n].to_sentence : original_hash[n] )}

    add_includes(filter_hash, original_hash) do |association, records, opts|
     hash[association.to_s] = if records.is_a?(Array)
       records.map { |a| filter(opts, a, true) }
     else
       filter(opts, records)
     end
    end
    hash
  end

  def self.add_includes(filter_hash, original_hash) #:nodoc:
    return unless includes = filter_hash[:include]

    unless includes.is_a?(Hash)
      includes = Hash[Array(includes).flat_map { |n| n.is_a?(Hash) ? n.to_a : [[n, {}]] }]
    end

    includes.each do |association, opts|
      if records = original_hash[association.to_s]
        yield association, records, opts
      end
    end
  end
end