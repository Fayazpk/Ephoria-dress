module Usermodule
  class AddressesController < ApplicationController
    before_action :set_address, only: %i[show edit update destroy]
    before_action :authenticate_user!

    def index
      @addresses = current_user.addresses
    end

    def show
    end

    def new
      @address = current_user.addresses.new
    end

    def edit
      @states = @address.country&.states || []
      @cities = @address.state&.cities || []
    end

    def create
      @address = current_user.addresses.build(address_params)
      if @address.save
        redirect_to usermodule_address_path(@address), notice: "Address was successfully created."
      else
        @states = @address.country&.states || []
        @cities = @address.state&.cities || []
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @address.update(address_params)
        redirect_to usermodule_address_path(@address), notice: "Address was successfully updated."
      else
        @states = @address.country&.states || []
        @cities = @address.state&.cities || []
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @address.destroy!
      redirect_to usermodule_addresses_path, notice: "Address was successfully destroyed."
    end

    def get_states
      states = State.where(country_id: params[:country_id]).select(:id, :name).order(:name)
      render json: states
    rescue
      render json: { error: "Failed to load states" }, status: :unprocessable_entity
    end

    def get_cities
      cities = City.where(state_id: params[:state_id]).select(:id, :name).order(:name)
      render json: cities
    rescue
      render json: { error: "Failed to load cities" }, status: :unprocessable_entity
    end

    private

    def set_address
      @address = current_user.addresses.find(params[:id])
    end

    def address_params
      params.require(:address).permit(:first_name, :last_name, :building_name, :street_address, :country_id, :state_id, :city_id, :phone, :country_name, :state_name, :city_name)
    end
  end
end