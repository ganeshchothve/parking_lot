class IncentiveCalculator
  attr_reader :resource, :channel_partner, :ladder, :options, :category

  def initialize(resource, category, options={test: false})
    @resource = resource
    @category = category
    @options = options
    # Find channel partner for above resource
    @channel_partner = resource.invoiceable_manager
  end

  def find_ladder(scheme, value)
    ladder_max_end_value = scheme.ladders.ne(end_value: nil).max(:end_value)
    @ladder = if ladder_max_end_value.blank? || value > ladder_max_end_value
                scheme.ladders.where(end_value: nil, start_value: { '$lte': value }).first
              elsif value <= ladder_max_end_value
                scheme.ladders.where(start_value: { '$lte': value }, end_value: { '$gte': value }).first
              end
  end

  # Run incentive calculation
  def calculate
    resource_hash={}
    if channel_partner && (schemes = resource.find_incentive_schemes(category))
      schemes.group_by {|is| [is.category, is.brokerage_type]}.each do |key, scheme_arr|
        scheme = scheme_arr.first
        resources = resource.find_all_resources_for_scheme(scheme)
        # sort on invoiceable_date & create a hash { 1 => { resource: booking1 }, 2 => { resource: booking2 } }
        resource_hash = resources.sort { |x| x.invoiceable_date }.each_with_index.inject({}) { |hash, (resource, idx)| hash[idx+1] = { resource: resource }; hash}

        if scheme.ladder_strategy == 'number_of_items'
          actual_value = resources.count
        elsif scheme.ladder_strategy == 'sum_of_value'
          actual_value = resources.sum {|x| x.invoiceable_price.to_f }
        end

        if find_ladder(scheme, actual_value)
          resource_hash.each do |idx, hash|
            _resource = hash[:resource]
            incentive_amount = ladder.payment_adjustment.value(_resource).try(:to_f).try(:round)
            if options[:test]
              hash[:incentive] = incentive_amount
            else
              invoice = Invoice::Calculated.find_or_initialize_by(project_id: _resource.try(:project_id), invoiceable: _resource, incentive_scheme_id: scheme.id, ladder_id: ladder.id, manager_id: channel_partner.id, category: scheme.category, brokerage_type: scheme.brokerage_type, booking_portal_client_id: _resource.try(:booking_portal_client_id))
              existing_invoices = Invoice::Calculated.where(booking_portal_client_id: _resource.try(:booking_portal_client_id), project_id: _resource.try(:project_id), invoiceable: _resource, incentive_scheme_id: scheme.id, manager_id: channel_partner.id, category: scheme.category, brokerage_type: scheme.brokerage_type)

              if invoice.new_record?
                # Only in case of booking we set the agreement amount on invoice.
                agreement_amount = (@resource.project.enable_inventory? ? (@resource.try(:calculate_agreement_price).try(:round) || 0) : (@resource.try(:agreement_price).try(:round) || 0))
                amount = (incentive_amount - existing_invoices.sum(:amount)).round
                invoice.agreement_amount = agreement_amount
                invoice.amount = (amount > 0 ? amount : 0)
                invoice.ladder_stage = ladder.stage
                invoice.payment_to = scheme.payment_to
                invoice.creator = User.admin.first
                if invoice.save
                  # Set incentive scheme id & ladder stage of scheme under which this resource is incentivized.
                  is_data = _resource.incentive_scheme_data&.clone || {}
                  is_data[scheme.id.to_s] = { ladder_stage: (1..ladder.stage).to_a }
                  _resource.set(incentive_scheme_data: is_data)
                else
                  Rails.logger.error "[IncentiveCalculator][ERR] #{invoice.errors.full_messages}"
                end
              end
            end
          end
        end
      end
    end

    resource_hash if options[:test]
  end
end
