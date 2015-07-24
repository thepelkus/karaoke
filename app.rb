require 'sinatra'
require 'haml'
require 'shellwords'
require 'socket'
require 'json'

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

get '/song/:songnumber/play' do
  song_lister = SongLister.new
  song_number = params[:songnumber].to_i
  song_name = song_lister.songs[song_number]
  full_song_path = File.join(Dir.pwd, song_name)

  def play_song_command songpath
    { "command" => [ "loadfile", songpath, "append-play" ] }.to_json
  end

  def go_fullscreen_command
    { "command" => [ "set_property_string", "fullscreen", "yes" ] }.to_json
  end

  s = UNIXSocket.new('/tmp/mpvsocket')
  s.puts play_song_command(full_song_path)
  s.puts go_fullscreen_command

  server_status = ""
  begin
    sleep 1.0
    server_status = s.recv_nonblock(1024)
  rescue
    "Nothing to read!"
  end
  s.close

  server_status

#  `bash -c "echo -n 'add #{full_song_path}' | nc -U /tmp/vlc.sock"`
#  "bash -c \"echo -n \\\"add #{full_song_path}\\\" | nc -U /tmp/vlc.sock\""
#  "bash -c \"echo -n \"add #{File.join(Dir.pwd, song_lister.songs[params[:songnumber].to_i])}\" | nc -U /tmp/vlc.sock\""
#  WORKS: `bash -c "echo -n \"pause\" | nc -U /tmp/vlc.sock"`
end
