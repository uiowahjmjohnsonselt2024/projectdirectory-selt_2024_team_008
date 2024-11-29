class ServersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update_status]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @servers = current_user.joined_servers
    respond_to do |format|
      format.html { render plain: "Servers list: #{@servers.map(&:name).join(', ')}" }
      format.json { render json: @servers.as_json(only: [:id, :name]) }
    end
  end

  def create
    @server = current_user.created_servers.new(server_params)
    if @server.save
      redirect_to @server
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @server = Server.includes(:memberships, :messages).find(params[:id])
    @messages = @server.messages.order(:created_at)
  end

  def ensure_membership
    @server = Server.find_by(id: params[:id])

    unless @server
      return render json: { error: "Server not found" }, status: :not_found
    end

    if @server.memberships.exists?(user: current_user)
      render json: { message: "Membership already exists" }, status: :ok
    else
      membership = @server.memberships.new(user: current_user)

      if membership.save
        render json: { message: "Membership ensured" }, status: :ok
      else
        render json: { error: "Unable to create membership: #{membership.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
      end
    end
  end

  def update_status
    return render json: { error: 'User not authenticated' }, status: :unauthorized unless user_signed_in?

    server = Server.find_by(id: params[:id])
    return render json: { error: 'Server not found' }, status: :not_found unless server

    status = params[:status].to_s.strip

    allowed_statuses = %w[online offline]
    return render json: { error: 'Invalid status' }, status: :bad_request unless allowed_statuses.include?(status)

    current_status = params[:status]
    ActionCable.server.broadcast(
      "server_#{server.id}",
      {
        type: 'status',
        user_id: current_user.id,
        status: current_status
      }
    )

    last_seen_at = params[:status] == 'online' ? Time.current : nil
    current_user.update_columns(last_seen_at: last_seen_at)

    render json: { message: "Status updated to #{params[:status]}" }, status: :ok
  end

  private

  def server_params
    params.require(:server).permit(:name)
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
end