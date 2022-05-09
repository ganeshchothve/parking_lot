module JSONStringParser
  extend ActiveSupport::Concern
  def recursive_json_string_parser(data)
    res = data
    case (res ||= data)
    when Hash
      res.each do |key, value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        res[key] = ((_value.is_a?(Hash) || _value.is_a?(Array)) ? recursive_json_string_parser(_value) : value)
      end
      res
    when Array
      res.map! do |value|
        _value = (SafeParser.new(value).safe_load rescue nil) || value
        (_value.is_a?(Hash) || _value.is_a?(Array)) ? recursive_json_string_parser(_value) : value
      end
      Array.new.push(*res)
    else
      res
    end
  end
end