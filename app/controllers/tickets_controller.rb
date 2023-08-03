class TicketsController < ApplicationController

  before_action :set_ticket, only: :update

  def new
    @ticket = Ticket.new
    @available_parking_sites = ParkingSite.all.map { |ps| [ps.name, ps.id] }
    if @available_parking_sites.any?
      render :new
    else
      redirect_to root_path, alert: 'Parking Sites Not Found', status: :unprocessable_entity
    end
  end

  def create
    spot = Spot.where(parking_site_id: ticket_params[:parking_site_id], status: 'available').first
    unless spot && check_spot_for_color_availability
      redirect_to new_ticket_path, alert: 'Sorry, Spot for this parking site is not available', status: :unprocessable_entity
    else
      @ticket = Ticket.new(
        spot_id: spot.id,
        status: 'active'
      )
      @ticket.assign_attributes(ticket_params)
      if @ticket.save
        move_spot_to_blocked(spot) #state machines
        redirect_to root_path, notice: 'Parking Spot Registered Successfully.', status: :ok
      else
        render :new, alert: @ticket.errors.messages.flatten.uniq, status: :unprocessable_entity
      end
    end
  end

  # will fire state machine events for event trasactions of spot for ticket
  # i.e. if ticket moved from active to expired
  # spot will move from blocked to available
  def update
  end

  private

  def set_ticket
    @ticket = Ticket.where(id: params[:id]).first
    redirect_to root_path unless @ticket
  end

  def ticket_params
    params.require(:ticket).permit(:spot_id, :parking_site_id, car_attributes: [:color, :reg_no])
  end

  def check_spot_for_color_availability
    t_params = ticket_params
    if psid = t_params[:parking_site_id]
      parking_site = ParkingSite.where(id: psid).first
      car_ids = parking_site.tickets.where(status: 'active').pluck(:car_id)
      if Car.in(id: car_ids).where(color: t_params.dig(:car, :color) ).any?
        return false
      else
        return true
      end
    end
    false
  end

  #state_machine
  def move_spot_to_blocked(spot)
    spot.status = 'blocked'
    spot.save
  end
end
