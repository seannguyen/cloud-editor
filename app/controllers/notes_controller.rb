class NotesController < ApplicationController
  FILE_QUERY_FIELDS = 'id, name, description, mimeType, iconLink, thumbnailLink, createdTime'
  
  before_action :init_google_drive_service
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  
  rescue_from Google::Apis::ServerError do
    # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
    render :google_internal_error
  end

  rescue_from Google::Apis::ClientError, Google::Apis::AuthorizationError, ArgumentError do
    # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
    # @raise [Google::Apis::AuthorizationError] Authorization is required
    redirect_to auth_index_url
  end
  
  # GET /notes
  # GET /notes.json
  def index
    @page_tokens = {
        last_page_token: request[:last_page_token],
        current_page_token: request[:current_page_token],
        next_page_token: nil
    }
    
    response = @google_drive_service.list_files(
        page_size: 10,
        page_token: @page_tokens[:current_page_token],
        order_by: "viewedByMeTime desc",
        q: '(mimeType contains "text" or mimeType contains "plain" or mimeType contains "google-apps")
               and trashed = false
               and not mimeType contains "folder"',
        fields: "nextPageToken, files(#{FILE_QUERY_FIELDS})")
    @notes = response.files
    @page_tokens[:next_page_token] = response.next_page_token
  end
  
  # GET /notes/1
  # GET /notes/1.json
  def show
    
  end
  
  # GET /notes/new
  def new
    @note = Note.new
  end
  
  # GET /notes/1/edit
  def edit
  end
  
  # POST /notes
  # POST /notes.json
  def create
    @note = Note.new(note_params)
    
    respond_to do |format|
      if @note.save
        format.html { redirect_to @note, notice: 'Note was successfully created.' }
        format.json { render :show, status: :created, location: @note }
      else
        format.html { render :new }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /notes/1
  # PATCH/PUT /notes/1.json
  def update
    render status: 400 and return if params[:content].nil?
    content = StringIO.new params[:content]

    @google_drive_service.update_file params[:id], upload_source: content
    render :text => content.string
  end
  
  # DELETE /notes/1
  # DELETE /notes/1.json
  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to notes_url, notice: 'Note was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_note
    begin
      content = @google_drive_service.get_file(params[:id], download_dest: StringIO.new)
    rescue
      content = @google_drive_service.export_file(params[:id], 'text/plain', download_dest: StringIO.new)
    end
    @note = content.string
  end
  
  def init_google_drive_service
    if session[:google_drive_credential].nil?
      redirect_to auth_index_path(redirect: request.original_url)
      return
    end
    
    client_opts = JSON.parse(session[:google_drive_credential])
    puts client_opts
    auth_client = Signet::OAuth2::Client.new(client_opts)
    @google_drive_service = Google::Apis::DriveV3::DriveService.new
    @google_drive_service.authorization = auth_client
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def note_params
    params.fetch(:note, {})
  end
end
