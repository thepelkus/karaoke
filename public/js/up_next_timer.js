var secondsToNextSong = 5;

$( ".next_song" ).append('<div id="countdown_container"><span id="up_next_countdown">' + secondsToNextSong + '</span> seconds until the next song!</div>');

var intervalId = 0;

function timerUpdate() {
  secondsToNextSong--;
  $( "#up_next_countdown" ).text(secondsToNextSong);
  if (secondsToNextSong <= 0) {
    clearInterval(intervalId);
    sendNextSongRequest();
  }
}

function sendNextSongRequest() {
  var full = location.protocol+'//'+location.hostname+(location.port ? ':'+location.port: '');
  var newUrl = full + "/finish_between";
  location.replace(newUrl);
}

intervalId = setInterval(timerUpdate, 1000);
