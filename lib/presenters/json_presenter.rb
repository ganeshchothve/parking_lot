module Presenters
  module JsonPresenter
# Assuming that data received is consistent in following ways
#   - Class of all elements in the array is same
    def self.json_to_html json, header
      obj = parse_json(json)
      base_card = "<div class='col-md-12'><div class = 'card'><div class = 'card-header'>#{header.to_s.titleize}</div><div class = 'card-body'><div class = 'row'>"
      base_card_end_tag = "</div></div></div></div>"
      html = ""
      obj.each do |key, value|
        case value
        when String
          base_card += "<div class='col-3'>
                          <div class='form-group'>
                            <label>#{key.titleize}</label>
                            <div>#{value}</div>
                          </div>
                        </div>"
        when Array
          case value.first
          when String
            base_card += "<div class='col-3'>
                            <div class='form-group'>
                              <label>#{key.titleize}</label>
                              <div>#{value.to_sentence}</div>
                            </div>
                          </div>"
          when Hash
            html += create_table(key, value.compact) if value.compact.present?
          end
        when Hash
          html += process_hash(key, value.compact) if value.compact.present?
        end
      end
      base_card + base_card_end_tag + html 
    end

    def self.parse_json json
      json_response = JSON.parse(json)
      obj = JWT.decode(json_response["data"], "56d620cfbd959a2b75e0116b234369d8")[0]
      obj.compact
    end

    def self.create_table header, arr
      card = "<div class='col-md-12'><div class = 'card'><div class = 'card-header'>#{header.titleize}</div><div class = 'card-body'><table class='table my-customer-table responsive-tbl'><thead class='th-default'>"
      card_end_tag = "</table></div></div></div>"
      card += "<tr>"
      index = 0
      keys = arr.first.keys[0..4] 
      keys.each do |key|
        card += "<th>#{key.titleize}</th>"
      end
      card += "</tr>"
      arr.each do |hash|
        card += "<tr>"
        keys.each do |key|
          if hash[key].is_a? String
            card += "<td>#{ hash[key] }</td>"
          elsif hash[key].is_a? Array
            if hash[key].first.is_a? String
              card += "<td>#{ hash[key].to_sentence }</td>"
            end
          end
        end
        card += "</tr>"
      end
      card + card_end_tag
    end

    def self.process_hash header, obj
      card = "<div class='col-md-12'><div class = 'card'><div class = 'card-header'>#{header.titleize}</div><div class = 'card-body'><div class = 'row'>"
      card_end_tag = "</div></div></div></div>"
      obj.each do |key, value|
        if key.class == String
          card += "<div class='col-3'>
                    <div class='form-group'>
                      <label>#{key.titleize}</label>
                      <div>#{value}</div>
                    </div>
                  </div>"
        end
      end
      card + card_end_tag
    end
  end
end