require 'sinatra'
require 'haml'
require 'shellwords'
require 'socket'
require 'json'

#set :port, 80

SLEEP_TIME = 0.1

class SongLister
  def songs
    mp3_files = File.join("**", "*.cdg")
    Dir.glob(mp3_files)
  end
end

get '/' do
  song_lister = SongLister.new
  haml :song_list, :format => :html5, :locals => { :songs => song_lister.songs }
end

#PLAYLIST
def make_playlist_command
  { "command" => ["get_property", "playlist"] }.to_json
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

def get_playlist
  s = UNIXSocket.new('/tmp/mpvsocket')
  sleep SLEEP_TIME
  #  clear_socket(s)
  s.puts make_playlist_command
  sleep SLEEP_TIME
  mpv_messages_string = read_all_from_socket(s)
  mpv_message_string_array = mpv_messages_string.split('\n')
  mpv_messages = mpv_message_string_array.map { |message_string|
    JSON.parse message_string
  } 
  mpv_playlists = mpv_messages.select { |message|
    message.has_key? "data"
  }
  latest_playlist = mpv_playlists.last
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

get '/playlist' do
  pl = get_playlist
  haml :playlist, :format => :html5, :locals => { :songs => pl }
end

#ADD SONG
get '/song/:songnumber/play' do
  song_lister = SongLister.new
  song_number = params[:songnumber].to_i
  song_name = song_lister.songs[song_number]
  full_song_path = File.join(Dir.pwd, song_name)

  def make_play_song_command songpath
    { "command" => [ "loadfile", songpath, "append-play" ] }.to_json
  end

  def go_fullscreen_command
    { "command" => [ "set_property_string", "fullscreen", "yes" ] }.to_json
  end

  s = UNIXSocket.new('/tmp/mpvsocket')
  s.puts make_play_song_command(full_song_path)
  sleep SLEEP_TIME
  s.puts go_fullscreen_command
  s.close

  if false
    server_status = ""
    begin
      sleep SLEEP_TIME
      server_status = s.recv_nonblock(1024)
    rescue
      "Nothing to read!"
    end
    s.close

    server_status
  end

  pl = get_playlist
  haml :playlist, 
       :format => :html5,
       :locals => { 
         flash_content: "Thanks for adding a song!", 
         songs: pl 
       }

  #  server_status = s.recv_nonblock(1024)
  #  parsed_playlist_data = JSON.parse(server_status.to_json)

  #  `bash -c "echo -n 'add #{full_song_path}' | nc -U /tmp/vlc.sock"`
  #  "bash -c \"echo -n \\\"add #{full_song_path}\\\" | nc -U /tmp/vlc.sock\""
  #  "bash -c \"echo -n \"add #{File.join(Dir.pwd, song_lister.songs[params[:songnumber].to_i])}\" | nc -U /tmp/vlc.sock\""
  #  WORKS: `bash -c "echo -n \"pause\" | nc -U /tmp/vlc.sock"`
end
