var ntris = {
  initialize: function() {
    $('button').button().click(function(event) {
      event.preventDefault();
    });
    $('ul').menu();
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

  board_callback: function(id, squareWidth) {
    var board = $('#' + id)[0];
    board.setSquareWidth(parseInt(squareWidth, 10));
    board.start();
  },
};

ntris.create_board('mainboard', 10);
