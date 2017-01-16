require 'google/apis/drive_v3'
require 'google/api_client/client_secrets'

class NotesController < ApplicationController
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  before_action :verify_google_drive_auth
  
  # GET /notes
  # GET /notes.json
  def index
    @notes = Note.all
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
  
  def verify_google_drive_auth
    # Check credential ofr gg drive has been in place yet
    return session[:google_drive_credential] if session[:google_drive_credential]
    
    # If not go ahead and get one
    client_secrets = Google::APIClient::ClientSecrets.load 'config/google_api_client_secret.json'
    auth_client = client_secrets.to_authorization
    auth_client.update!(
        :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
        :redirect_uri => request.original_url
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
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def note_params
    params.fetch(:note, {})
  end
end
