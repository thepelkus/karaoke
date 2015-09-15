require 'sinatra'
require 'haml'
require 'shellwords'
require 'socket'
require 'json'
require 'uri'

# Startup things?

def attempt_to_ensure_mpv
  return if /idle/.match(`ps aux | grep mpv`)

  pid = Process.fork
  if pid.nil? then
    exec "mpv --idle --input-unix-socket=/tmp/mpvsocket"
  else
    Process.detach(pid)
  end
end

attempt_to_ensure_mpv

# Constants!
if File.exists? 'config.rb'
  require_relative 'config.rb'
elsif File.exists? 'config.rb.example'
  load 'config.rb.example'
  warning_message = "YOU ARE USING THE EXAMPLE CONFIGURATION FILE. PLEASE REPLACE THIS WITH A CUSTOM VERSION AS SOON AS POSSIBLE"
  puts "++++++++++++++++++"
  puts warning_message
  puts "++++++++++++++++++"
else
  puts "THERE IS NO CONFIGURATION FILE AVAILABLE"
end

# Routes!

get '/' do
  songs = CachedSongLister.new().songs
  haml :song_list, :format => :html5, :locals => { :songs => songs.take(CHUNK_SIZE) }
end

get '/build_catalog' do
  song_lister = SongLister.new
  songs = song_lister.songs
  File.open(CATALOG_JSON_PATH,"w") do |f|
    f.write(songs.to_json)
  end
end

get '/controls' do
  haml :controls, :format => :html5
end

get '/search/:searchterm' do
  songs = CachedSongLister.new().songs.find_all { |song| /#{params[:searchterm]}/i.match(song["relative_path"])  }
  haml :song_list, :format => :html5, :locals => { :songs => songs }
end

get '/playlist' do
  pl = get_playlist
  haml :playlist,
    :format => :html5,
    :locals => {
      :songs => pl
    }
end

get '/playlist_entry/:listposition' do
  entry_title = entry_title_for_playlist_position params[:listposition]

  haml :playlist_entry,
    :format => :html5,
    :locals => {
      entry_title: entry_title,
      entry_position: params[:listposition]
    }
end

def entry_title_for_playlist_position position
  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  clear_socket(s)
  s.puts entry_title_for_playlist_position_command(position)
  sleep SLEEP_TIME

  mpv_messages_string = read_all_from_socket(s)
  mpv_message_string_array = mpv_messages_string.split("\n")
  mpv_messages = mpv_message_string_array.map { |message_string|
    logger.info("plp msg string: " + message_string)
    JSON.parse message_string
  }
  return "" unless mpv_messages.size > 0

  return mpv_messages[0]["data"]
end

def entry_title_for_playlist_position_command(position)
  { "command" => ["get_property_string", "playlist/#{position}/filename"] }.to_json
end

get '/song/:songnumber/play' do
  play_song_by_id(params[:songnumber].to_i)
  pl = get_playlist

  haml :playlist,
    :format => :html5,
    :locals => {
      flash_content: "Thanks for adding a song!",
      songs: pl
    }
end

get '/up_next' do
  # should we check the status of the player?
  # should we check the origin of the request?
  next_song = get_current_song

  if next_song
    haml :up_next,
      :locals => {
      next_song: next_song
    }
  else
    haml :no_more_songs
  end
end

get '/finish_between' do
  show_mpv
  play_mpv

  haml :finish_between
end

get '/skip_current' do
  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  clear_socket(s)
  s.puts skip_to_next_track_command
  sleep SLEEP_TIME

  pl = get_playlist

  haml :playlist,
    :format => :html5,
    :locals => {
      flash_content: "Song skipped!",
      songs: pl
    }
end

get '/delete_from_playlist/:playlist_entry_number' do
  playlist_entry_number = params[:playlist_entry_number].to_i

  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  clear_socket(s)
  s.puts delete_playlist_entry_command(playlist_entry_number)
  sleep SLEEP_TIME

  pl = get_playlist

  haml :playlist,
    :format => :html5,
    :locals => {
      flash_content: "Song removed from playlist!",
      songs: pl
    }
end

# API ROUTES
get '/api/songs' do
  CachedSongLister
    .new()
    .songs()
    .take(CHUNK_SIZE)
    .to_json
end

get '/api/songs/:page' do
  page_number = params[:page].to_i

  CachedSongLister
    .new()
    .songs()
    .slice(CHUNK_SIZE*page_number,CHUNK_SIZE)
    .to_json
end

get '/api/songs/from/:song_offset' do
  drop_count = params[:song_offset].to_i

  CachedSongLister
    .new()
    .songs()
    .drop(drop_count)
    .to_json
end

get '/api/search/:searchterm' do
  search_string = Regexp.escape(URI.unescape(params[:searchterm]))
  logger.info search_string
  search_regex = /#{search_string}/i
  songs = CachedSongLister
          .new()
          .songs
          .find_all { |song| search_regex.match(song["relative_path"]) }
          .take(100)
          .to_json
end

get '/api/search/:searchterm/:page' do
  search_regex = /#{params[:searchterm]}/i
  page_number = params[:page].to_i

  songs = CachedSongLister
          .new()
          .songs
          .find_all { |song| search_regex.match(song["relative_path"]) }
  songs.slice(CHUNK_SIZE*page_number,CHUNK_SIZE).to_json
end

get '/api/alphabet/:letter' do
  search_regex = /^#{params[:letter]}/i
  songs = CachedSongLister
          .new()
          .songs
          .find_all { |song| search_regex.match(song["artist"]) }
          .to_json
end

# NOT ROUTES!
def delete_playlist_entry_command(playlist_entry_number)
  { "command" => ["playlist_remove", playlist_entry_number.to_s] }.to_json
end

def unpause_command
  { "command" => ["set_property_string", "pause", "no"] }.to_json
end

def make_play_song_command songpath
  { "command" => [ "loadfile", songpath, "append-play" ] }.to_json
end

def go_fullscreen_command
  { "command" => [ "set_property_string", "fullscreen", "yes" ] }.to_json
end

def make_get_current_song_command
  { "command" => ["get_property", "media-title"] }.to_json
end

def make_playlist_command
  { "command" => ["get_property", "playlist"] }.to_json
end

def skip_to_next_track_command
  { "command" => ["playlist-next"] }.to_json
end

def play_song_by_id(song_index)
  song_lister = CachedSongLister.new
  song_name = song_lister.songs.find { |song|
    song["id"] == song_index
  }["relative_path"]
  full_song_path = song_name

  s = UNIXSocket.new('/tmp/mpvsocket')
  s.puts make_play_song_command(full_song_path)
  sleep SLEEP_TIME
  s.puts go_fullscreen_command
  s.close
end

def show_mpv
  `./system_scripts/show_mpv.script`
end

def play_mpv
  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  s.puts unpause_command
end

def get_current_song
  current_song = nil

  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  clear_socket(s)
  sleep SLEEP_TIME
  s.puts make_get_current_song_command
  sleep SLEEP_TIME
  mpv_messages_string = read_all_from_socket(s)
  mpv_message_string_array = mpv_messages_string.split("\n")
  mpv_messages = mpv_message_string_array.map { |message_string|
    JSON.parse message_string
  }
  mpv_data_messages = mpv_messages.select { |message|
    message.has_key? "data"
  }
  if mpv_data_messages.last
    current_song = mpv_data_messages.last["data"]
  end

  current_song
end

def metadata_guess_from_filepath filepath
  file = File.basename(filepath, ".cdg")
  *_, artist_guess, title_guess = file.split(" - ")
  {
    title: title_guess,
    artist: artist_guess,
    relative_path: filepath
  }
end

class SongLister
  def songs
    all_cdg_files().map { |filepath|
      metadata_guess_from_filepath filepath
    }.each_with_index { |songdata,index|
      songdata[:id] = index
    }.sort_by { |song| [song[:artist], song[:title]] }
  end

  def all_cdg_files
    mp3_files = File.join(KARAOKE_LIBRARY_ROOT, "**", "*.cdg")
    Dir.glob(mp3_files)
  end
end

class CachedSongLister
  def songs
    json_source = File.read(CATALOG_JSON_PATH)
    songs = JSON.parse(json_source)
  rescue
    {}
  end
end

def read_all_from_socket(socket)
  socket_data = ""
  begin
    while buf = socket.recv_nonblock(1024)
      socket_data << buf
    end
  rescue
    socket_data
  end
end

def clear_socket(socket)
  read_all_from_socket(socket)
end

def get_playlist_data_from_socket
  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  clear_socket(s)
  s.puts make_playlist_command
  sleep SLEEP_TIME
  mpv_messages_string = read_all_from_socket(s)
  mpv_message_string_array = mpv_messages_string.split("\n")
  mpv_messages = mpv_message_string_array.map { |message_string|
    logger.info("pl msg string: " + message_string)
    JSON.parse message_string
  }
  mpv_playlists = mpv_messages.select { |message|
    message.has_key? "data"
  }
  latest_playlist = mpv_playlists.last
end

PLAYLIST_RETRY_COUNT = 1
def get_playlist
  playlist_attempts_remaining = PLAYLIST_RETRY_COUNT
  latest_playlist = nil
  while playlist_attempts_remaining > 0 && !latest_playlist
    latest_playlist = get_playlist_data_from_socket
    sleep SLEEP_TIME
  end
  pl = []
  latest_playlist["data"].each { |playlist_entry|
    playlist_entry = {
      name: playlist_entry["filename"].split("/").last,
      current: playlist_entry.fetch("current", false)
    }
    pl.push playlist_entry
  }
  pl
end
