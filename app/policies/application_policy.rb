class ApplicationPolicy
  include ApplicationHelper

  attr_reader :user, :record, :condition

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def permitted_attributes params={}
    []
  end

  def editable_field? field
    permitted = permitted_attributes.include?(field.to_sym) || permitted_attributes.include?(field.to_s)
    if !permitted
      nested_fields = permitted_attributes.select{|k| k.is_a?(Hash)}
      nested_fields.each do |hash|
        permitted = (hash.keys.include?(field.to_sym) || hash.keys.include?(field.to_s)) if !permitted
      end
    end
    permitted
  end

  def editable_fields
    permitted_fields = permitted_attributes.map do |field|
      field.is_a?(Hash) ? field.keys : field
    end
    permitted_fields.flatten.map(&:to_s)
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def current_user_role_group
    user.buyer? ? :Buyer : :Admin
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  private

  def only_for_admin!
    return true if !user.buyer?
    @condition = 'only_admin'
    false
  end

  def only_for_buyer!
    return true if user.buyer?
    @condition = 'only_buyer'
    false
  end

  def enable_actual_inventory?(_user=nil)
    _user ||= user
    return true if current_client.enable_actual_inventory?(_user)
    @condition = 'enable_actual_inventory'
    false
  end

  def enable_incentive_module?(_user=nil)
    _user ||= user
    return true if current_client.enable_incentive_module?(_user)
    @condition = 'enable_incentive_module'
    false
  end

  def only_for_confirmed_user!
    return true if record.user.confirmed?
    @condition = 'only_for_confirmed_user'
    false
  end

  def only_for_kyc_added_users!
    return true if record.user.try(:kyc_ready?)
    @condition = 'only_for_kyc_added_users'
    false
  end

  def has_user_on_record?
    return true if record.user_id.present?
    @condition = 'user_missing'
    false
  end


end
