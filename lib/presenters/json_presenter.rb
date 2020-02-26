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
            html += create_table(key, value.compact) if value.present?
          end
        when Hash
          html += process_hash(key, value) if value.present?
        end
      end
      base_card + base_card_end_tag + html 
    end

    def self.create_table header, arr
      card = get_table_card(header) + "<table class='table my-customer-table responsive-tbl'><thead class='th-default'>"
      card_end_tag = "</table></div></div></div>"
      card += "<tr class='bg-gradient-cd white'>"
      index = 0
      keys = arr.first.keys[0..4] 
      keys.each do |key|
        card += "<th>#{key.to_s.titleize}</th>"
      end
      card += "</tr>"
      arr.each do |hash|
        card += "<tr>"
        keys.each do |key|
          if hash[key].is_a? Array
            if hash[key].first.is_a? String
              card += "<td>#{ hash[key].to_sentence }</td>"
            end
          elsif hash[key].is_a?(String)
            card += "<td>#{ hash[key].to_s.titleize }</td>"
          else
            card += "<td>#{ hash[key] }</td>"
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
          <label>#{key.to_s.titleize}</label>
          <div>#{value.is_a?(Array) ? value.to_sentence : (value.is_a?(String) ? value.to_s.titleize : value)}</div>
        </div>
      </div>"
    end

    def self.get_card header
      "<div class='col-md-12 pt-3'><div class='box-card'><div class='box-header bg-gradient br-rd-tr-4'><h2>#{header.to_s.titleize}</h2></div><div class='box-content br-rd-bl-4 bg-white pl-2'>"
    end

    def self.get_table_card header
      "<div class='col-md-12 pt-3'><div class='box-card'><div class='col-lg-6 col-xs-12 col-md-6 col-sm-12 pt-3 pb-0 pl-0'>
        <div class='table-title pt-1'>
          <h1 class='title'>
            #{header.to_s.titleize}
          </h1>
        </div>
      </div> <div class='box-content br-rd-bl-4 bg-white pl-2'>"
    end
  end
end