require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'

class NotesController < ApplicationController
  before_action :verify_google_api_auth
  before_action :init_google_drive_service
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  
  # GET /notes
  # GET /notes.json
  def index
    @page_tokens = {
        last_page_token: request[:last_page_token],
        current_page_token: request[:current_page_token],
        next_page_token: nil
    }
    
    # TODO: catch all kind of error throw by this end point
    response = @google_api_service.list_files(
        page_size: 10,
        page_token: @page_tokens[:current_page_token],
        order_by: "viewedByMeTime desc",
        q: '(mimeType contains "text" or mimeType contains "plain" or mimeType contains "google-apps")
             and trashed = false
             and not mimeType contains "folder"',
        fields: 'nextPageToken, files(id, name, description, mimeType, iconLink, thumbnailLink, createdTime)')
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
    respond_to do |format|
      if @note.update(note_params)
        format.html { redirect_to @note, notice: 'Note was successfully updated.' }
        format.json { render :show, status: :ok, location: @note }
      else
        format.html { render :edit }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
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
    @note = Note.find(params[:id])
  end
  
  def verify_google_api_auth
    # Check credential ofr gg drive has been in place yet
    return session[:google_drive_credential] if session[:google_drive_credential]
    
    # If not go ahead and get one
    client_secrets = Google::APIClient::ClientSecrets.load 'config/google_api_client_secret.json'
    auth_client = client_secrets.to_authorization
    auth_client.update!(
        :scope => Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY,
        :redirect_uri => 'http://127.0.0.1:3000/' #request.original_url
    )
    
    if request[:code] == nil
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri
    else
      auth_client.code = request['code']
      auth_client.fetch_access_token!
      auth_client.client_secret = nil
      session[:google_drive_credential] = auth_client.to_json
    end

  end
  
  def init_google_drive_service
    client_opts = JSON.parse(session[:google_drive_credential])
    auth_client = Signet::OAuth2::Client.new(client_opts)
    @google_api_service = Google::Apis::DriveV3::DriveService.new
    @google_api_service.authorization = auth_client
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def note_params
    params.fetch(:note, {})
  end
end
