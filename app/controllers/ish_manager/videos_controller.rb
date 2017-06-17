
class IshManager::VideosController < IshManager::ApplicationController
  
  def index
    authorize! :index, Video.new
    @videos = Video.all.where( :site_id => @site.id )

    if params[:city_id]
      city = City.find params[:city_id]
      @videos = @videos.where( :city => city )
    end

    if params[:tag_it]
      tag = Tag.find params[:tag_id]
      @videos = @videos.where( :tag => tag )
    end
    
    @videos = @videos.page( params[:videos_page] ).per( Video::PER_PAGE )

    respond_to do |format|
      format.html do
        render
      end
      format.json do
        render :json => @videos
      end
    end
  end

  def show
    @video = Video.where( :youtube_id => params[:youtube_id] ).first
    @video ||= Video.unscoped.find params[:id]
    authorize! :show, @video

    respond_to do |format|
      format.html
      format.json do
        render :json => @video
      end
    end
  end

  def new
    @video = Video.new
    authorize! :new, @video

    @tags_list = Tag.unscoped.or( { :is_public => true }, { :user_id => current_user.id } ).list
    @cities_list = City.list
  end
  
  def create
    @video = Video.new params[:video].permit!
    @video.user = current_user
    if params[:video][:site_id]
      @video.site = Site.find params[:video][:site_id]
    else
      @video.site = @site
    end
    authorize! :create, @video
    
    if @video.save
      flash[:notice] = 'Success'      
      expire_page :controller => 'sites', :action => 'show', :domainname => @site.domain
      redirect_to organizer_path
    else
      flash[:error] = 'No luck'
      @tags_list = Tag.list
      @cities_list = City.list
      render :action => 'new'
    end
  end
  
  def edit
    @video = Video.unscoped.find params[:video_id]
    authorize! :edit, @video
    
    @tags_list = Tag.unscoped.or( { :is_public => true }, { :user_id => current_user.id } ).list
    @cities_list = City.list
  end

  def update
    @video = Video.unscoped.find params[:video_id]
    authorize! :update, @video

    @video.update params[:video].permit!
    if @video.save
      flash[:notice] = 'Success.'
      redirect_to organizer_path
    else
      flash[:error] = "No luck: #{@video.errors}"
      render :edit
    end
  end
  
end
