class IncentiveCalculator
  attr_reader :booking_detail, :unit, :lead, :channel_partner, :incentive_scheme, :ladder, :bookings, :options

  def initialize(booking_detail, options={test: false})
    @booking_detail = booking_detail
    @lead = booking_detail.lead
    @unit = booking_detail.project_unit
    @options = options
    # Find channel partner for above booking
    @channel_partner = lead.manager
  end

  # Find incentive scheme based on above
  def find_incentive_scheme
    tower_id = unit.project_tower_id
    tier_id = channel_partner.tier_id
    booked_on = booking_detail.booked_on
    incentive_schemes = IncentiveScheme.approved.where(project_id: lead.project_id).lte(starts_on: booked_on).gte(ends_on: booked_on)
    # Find tier level scheme
    if tier_id
      _incentive_scheme ||= (incentive_schemes.where(project_tower_id: tower_id, tier_id: tier_id).first || incentive_schemes.where(tier_id: tier_id, project_tower_id: nil).first)
    end
    # Find tower level scheme
    _incentive_scheme ||= incentive_schemes.where(project_tower_id: tower_id, tier_id: nil).first
    # Find project level scheme
    _incentive_scheme ||= incentive_schemes.where(project_tower_id: nil, tier_id: nil).first
    # Use default scheme if not found any of above
    _incentive_scheme ||= IncentiveScheme.where(default: true).first
    @incentive_scheme = _incentive_scheme
  end

  # Find all the bookings for above channel partner that fall under this scheme
  def find_all_bookings_for_current_scheme
    booking_details = BookingDetail.incentive_eligible.where(project_id: incentive_scheme.project_id, incentive_scheme_id: incentive_scheme.id, manager_id: channel_partner.id).gte(booked_on: incentive_scheme.starts_on).lte(booked_on: incentive_scheme.ends_on)
    booking_details = booking_details.where(project_tower_id: incentive_scheme.project_tower_id) if incentive_scheme.project_tower_id.present?
    @bookings = BookingDetail.or(booking_details.selector, {id: booking_detail.id})
  end

  def find_ladder(value)
    ladder_max_end_value = incentive_scheme.ladders.ne(end_value: nil).max(:end_value)
    @ladder = if ladder_max_end_value.blank? || value > ladder_max_end_value
                incentive_scheme.ladders.where(end_value: nil, start_value: { '$lte': value }).first
              elsif value <= ladder_max_end_value
                incentive_scheme.ladders.where(start_value: { '$lte': value }, end_value: { '$gte': value }).first
              end
  end

  # Run incentive calculation
  def calculate
    if channel_partner && find_incentive_scheme && find_all_bookings_for_current_scheme
      # sort on booked_on & create a hash { 1 => { booking_detail: booking1 }, 2 => { booking_detail: booking2 } }
      bookings_hash = bookings.sort { |x| x.booked_on }.each_with_index.inject({}) { |hash, (bd, idx)| hash[idx+1] = { booking_detail: bd }; hash}

      if incentive_scheme.ladder_strategy == 'number_of_items'
        actual_value = bookings.count
      elsif incentive_scheme.ladder_strategy == 'sum_of_value'
        actual_value = bookings.sum {|x| x.calculate_agreement_price }
      end

      if find_ladder(actual_value)
        bookings_hash.each do |idx, hash|
          _booking_detail = hash[:booking_detail]
          incentive_amount = ladder.payment_adjustment.value(_booking_detail).try(:to_f).try(:round)
          if options[:test]
            hash[:incentive] = incentive_amount
          else
            invoice = Invoice.find_or_initialize_by(project_id: _booking_detail.project_id, booking_detail_id: _booking_detail.id, incentive_scheme_id: incentive_scheme.id, ladder_id: ladder.id, manager_id: channel_partner.id)
            existing_invoices = Invoice.where(project_id: _booking_detail.project_id, booking_detail_id: _booking_detail.id, incentive_scheme_id: incentive_scheme.id, manager_id: channel_partner.id)

            if invoice.new_record?
              amount = (incentive_amount - existing_invoices.sum(:amount)).round
              invoice.amount = (amount > 0 ? amount : 0)
              invoice.ladder_stage = ladder.stage
              invoice.manager = channel_partner
              if invoice.save
                # Set incentive scheme id of scheme under which this booking detail is incentivized.
                _booking_detail.set(incentive_scheme_id: incentive_scheme.id) if _booking_detail.incentive_scheme_id.blank?
              else
                Rails.logger.error "[IncentiveCalculator][ERR] #{invoice.errors.full_messages}"
              end
            end
          end
        end
      end
    end

    bookings_hash if options[:test]
  end
end
