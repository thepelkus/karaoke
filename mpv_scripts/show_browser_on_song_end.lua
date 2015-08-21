utils = require 'mp.utils'

function on_song_end_show_browser(event)
  --os.execute("/Users/kai/personal/sites/karaoke/system_scripts/show_browser.script")
  os.execute("open http://localhost:4567/up_next")

  there_are_more_songs = tonumber(mp.get_property("playlist-count")) > 0

  if there_are_more_songs then
    mp.set_property("pause", "yes")
  end
end
mp.register_event("end-file", on_song_end_show_browser)
