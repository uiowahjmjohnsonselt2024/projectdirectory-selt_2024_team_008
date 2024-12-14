class InstructionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @origin = params[:origin]
  end
end