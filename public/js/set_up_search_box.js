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

  $("#search").keyup(_.debounce(function() {
    var searchString = $("#search").val();
    var searchUrl = "/api/search/"+encodeURIComponent(searchString);

    if (searchString == "") {
      searchUrl = "/api/songs";
    }

    $.getJSON(searchUrl, function(data, statusString) {
      replaceSonglistWithFormattedData(data);
    });
  }, 300));
}(jQuery);
