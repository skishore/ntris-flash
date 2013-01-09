var ntris = {
  initialize: function() { 
    $('#tabs').tabs();
    $('button').button().click(function(event) {
      event.preventDefault();
    });

    $('#users').menu();
    $('#rooms').menu();
    // TODO: Figure out why we need to subtract 5.
    $('#chat').width($('#chatbox').width() - $('#chatheader').width() - 5);
  },

  // Blocks on loading Board.swf.
  create_board: function(id, squareWidth) {
    var width = 14*squareWidth + Math.floor(7*squareWidth/2);
    var height = 26*squareWidth;
    swfobject.embedSWF('Board.swf', id, width, height, '10', null, {
      html_id: id,
      squareWidth: squareWidth,
    });
  },

  board_callback: function(id) {
    var board = $('#' + id)[0];
    board.start();
  },

  log_framerate: function(id, framerate) {
    //console.log('FPS (' + id + '): ' + framerate);
  },
};

//ntris.create_board('mainboard', 10);
//setTimeout(function() {
//  board = $('#mainboard')[0];
//}, 1000);
