!function($) {
  function replaceSonglistWithFormattedData(data) {
    var $songlistContainer = $(".song-list");
    $songlistContainer.html("");

    data.forEach(function(songData,index){
      var $newContent = songElement(songData,index);
      $songlistContainer.append($newContent);
    });
  }

  function songElement(songData, index) {
    return $("<li class='catalog_entry'><a href='/song/"+songData['id']+"/play'><div class='artist'>"+songData['artist']+"</div><div class='title'>"+songData['title']+"</div></a></li>");
  }

  $("#letter_picker").change(function() {
    var letter = $("#letter_picker").val();
    var searchUrl = "/api/alphabet/"+letter;

    if (letter == "-") {
      searchUrl = "/api/songs";
    }

    $.getJSON(searchUrl, function(data, statusString) {
      replaceSonglistWithFormattedData(data);
    });
  });
}(jQuery);
