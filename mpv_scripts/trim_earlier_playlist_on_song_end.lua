function on_song_end_remove_last_song(event)
  mp.commandv("playlist-remove", 0)
end
mp.register_event("end-file", on_song_end_remove_last_song)
