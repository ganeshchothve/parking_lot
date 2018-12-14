class AuditRecord
  include Mongoid::Document

  store_in collection: 'audits'

  field :subject_class, type: String, default: ""
  field :modified_at, type: String
  field :user_name, type: String, default: ""
  field :change_type, type: String, default: ""





  def subject_classes 
    AuditRecord.distinct(:subject_class)
  end
  def self.build_criteria params={}
    selector = {}
    if params[:fltrs].present?
      if params[:fltrs][:change_type].present?
        selector[:change_type] = params[:fltrs][:change_type]
      end
      if params[:fltrs][:subject_class].present?
        selector[:subject_class] = params[:fltrs][:subject_class]
      end
      if params[:fltrs][:user_name].present?
        selector[:user_name] = params[:fltrs][:user_name]
      end
      if params[:fltrs][:modified_at].present?
        selector[:modified_at] = params[:fltrs][:modified_at]
      end
    end
    selector[:name] = ::Regexp.new(::Regexp.escape(params[:q]), 'i') if params[:q].present?
    self.where(selector)
  end

end
