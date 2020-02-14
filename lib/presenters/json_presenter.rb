module Presenters
  module JsonPresenter
# Assuming that data received is consistent in following ways
#   - Class of all elements in the array is same
    def self.json_to_html obj, header
      return "" if obj.blank?
      base_card = get_card(header) + "<div class = 'row'>"
      base_card_end_tag = "</div></div></div></div>"
      html = ""
      obj.each do |key, value|
        case value
        when String
          base_card += get_column(key, value)
        when Array
          case value.first
          when String
            base_card += get_column(key, value)
          when Hash
            html += create_table(key, value.compact) if value.compact.present?
          end
        when Hash
          html += process_hash(key, value.compact) if value.compact.present?
        end
      end
      base_card + base_card_end_tag + html 
    end

    def self.create_table header, arr
      card = get_card(header) + "<table class='table my-customer-table responsive-tbl'><thead class='th-default'>"
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
      card = get_card(header) + "<div class = 'row'>"
      card_end_tag = "</div></div></div></div>"
      obj.each do |key, value|
        if key.class == String
          card += get_column(key, value)
        end
      end
      card + card_end_tag
    end

    def self.get_column key, value
      "<div class='col-3'>
        <div class='form-group'>
          <label>#{key.titleize}</label>
          <div>#{value}</div>
        </div>
      </div>"
    end

    def self.get_card header
      "<div class='col-md-12'><div class = 'card pt-3'><div class = 'card-header'>#{header.to_s.titleize}</div><div class = 'card-body'>"
    end
  end
end