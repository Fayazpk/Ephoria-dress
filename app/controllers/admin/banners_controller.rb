class Admin::BannersController < ApplicationController
    layout 'admin'
    def index
      @banners = Banner.all 
    end

    def show
      @banner = Banner.find(params[:id]) 
    end
  
    def new
      @banner = Banner.new 
    end
  
    def create
      @banner = Banner.new(banner_params)
  
      if @banner.save
        redirect_to @banner, notice: "Banner Created"
      else
        render :new 
      end
    end
  
    def edit
      @banner = Banner.find(params[:id]) 
    end
  
    def update
      @banner = Banner.find(params[:id])
  
      if @banner.update(banner_params)
        redirect_to @banner, notice: 'Banner was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @banner = Banner.find(params[:id])
      @banner.destroy
  
      redirect_to admin_banners_path, notice: 'Banner was successfully destroyed.'
    end
  
    private
  
    def banner_params
      params.require(:banner).permit(:title, :description, :active, images: [])
    end
end
