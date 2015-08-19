;(function($, window, undefined) {
  "use strict";

  $.fn.searcharoke = function(options) {

    var defaults = {
      list:           '.song-list',
      nodata:         '',
      attribute:      'text',
      highlight:      false,
      ignore:         '',
      navigation:     false,
      ignore_accents: false,
      hidden_mode:    false
    };

    var options = $.extend(defaults, options);

    return this.each(function() {

      var $this = $(this);

      $this.opts = [];

      $.map( ['list', 'nodata', 'attribute', 'highlight', 'ignore', 'navigation', 'ignore_accents', 'hidden_mode'], function( val, i ) {
        $this.opts[val] = $this.data(val) || options[val];
      } );

      var $list = $($this.opts.list);

      if ($this.opts.navigation)  $this.attr('autocomplete', 'off');

      if ($this.opts.hidden_mode) $list.children().hide();

      $this.keyup(function(e) {

        if (e.keyCode != 38 && e.keyCode != 40 && e.keyCode != 13) {

          var q = $this.val().toLowerCase();

          $list.children($this.opts.ignore.trim() ? ":not(" + $this.opts.ignore + ")" : '').removeClass('selected').each(function() {

            var data = ($this.opts.attribute != 'text') ? $(this).attr($this.opts.attribute).toLowerCase() : $(this).text().toLowerCase();

            var treaty = data.removeAccents($this.opts.ignore_accents).indexOf(q) == -1 || q === ($this.opts.hidden_mode ? '' : false)

            if (treaty) {

              $(this).hide();

              $this.trigger('_after_each');

            } else {

              $this.opts.highlight ? $(this).removeHighlight().highlight(q).show() : $(this).show();

              $this.trigger('_after_each');

            }

          });

          // No results message
          if ($this.opts.nodata) {

            $list.find('.no-results').remove();

            if (!$list.children(':not([style*="display: none"])').length) {

              $list
                .children()
                .first()
                .clone()
                .removeHighlight()
                .addClass('no-results')
                .show()
                .prependTo($this.opts.list)
                .text($this.opts.nodata);

            }

          }

          $this.trigger('_after');

        };

        // Navigation
        function current(element) {
          return element.children('.selected:visible');
        };

        function prev(element) {
          return current(element).prevAll(":visible:first");
        };

        function next(element) {
          return current(element).nextAll(":visible:first");
        };

        if ($this.opts.navigation) {

          if (e.keyCode == 38) {

            if (current($list).length) {

              prev($list).addClass('selected');

              current($list).last().removeClass('selected');

            } else {

              $list.children(':visible').last().addClass('selected');

            };

          } else if (e.keyCode == 40) {

            if (current($list).length) {

              next($list).addClass('selected');

              current($list).first().removeClass('selected');

            } else {

              $list.children(':visible').first().addClass('selected');

            };

          } else if (e.keyCode == 13) {

            if (current($list).find('a').length) {

              document.location = current($list).find('a').attr('href');

            } else {

              $this.val(current($list).text());

            };

          };

        };

      });

    });

  };

  $(document).ready(function () { $('[data-toggle="searchresults"]').searcharoke(); });

})(jQuery);

/*

highlight v4

Highlights arbitrary terms.

<http://johannburkard.de/blog/programming/javascript/highlight-javascript-text-higlighting-jquery-plugin.html>

MIT license.

Johann Burkard
<http://johannburkard.de>
<mailto:jb@eaio.com>

*/
jQuery.fn.highlight=function(t){function e(t,i){var n=0;if(3==t.nodeType){var a=t.data.removeAccents(true).toUpperCase().indexOf(i);if(a>=0){var s=document.createElement("mark");s.className="highlight";var r=t.splitText(a);r.splitText(i.length);var o=r.cloneNode(!0);s.appendChild(o),r.parentNode.replaceChild(s,r),n=1}}else if(1==t.nodeType&&t.childNodes&&!/(script|style)/i.test(t.tagName))for(var h=0;h<t.childNodes.length;++h)h+=e(t.childNodes[h],i);return n}return this.length&&t&&t.length?this.each(function(){e(this,t.toUpperCase())}):this},jQuery.fn.removeHighlight=function(){return this.find("mark.highlight").each(function(){with(this.parentNode.firstChild.nodeName,this.parentNode)replaceChild(this.firstChild,this),normalize()}).end()};

// Ignore accents
String.prototype.removeAccents = function(enabled) {
  if (enabled) return this
                      .replace(/[áàãâä]/gi,"a")
                      .replace(/[éè¨ê]/gi,"e")
                      .replace(/[íìïî]/gi,"i")
                      .replace(/[óòöôõ]/gi,"o")
                      .replace(/[úùüû]/gi, "u")
                      .replace(/[ç]/gi, "c")
                      .replace(/[ñ]/gi, "n");
  return this;
}
