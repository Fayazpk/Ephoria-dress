class CountriesController < ApplicationController
  def index
    render json: State.call(params[:country])
  end
end
