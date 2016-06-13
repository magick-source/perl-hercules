jQuery(document).ready(function($) {

  // re-elect group
  $('.btn-elect-group').click(function(){
    var group = $(this)[0].id;
    if (group == "")
      return

    group = group.replace('elect-group-','');

    $('#relect-confirm').find('.group-name').text(group);
    $('#group-to-reelect').val( group );
    $('#relect-confirm').modal('show');

    console.log( $(this) );
    console.log( "group-name: " + group );
  });

  $('#relect-confirm').find('.btn-primary').click(function() {
    group = $('#group-to-reelect').val();
    
    console.log("going to re-elect group"+group);
    $('#relect-confirm').modal('hide');
    $('#spinner-modal').modal('show');
    var url = '/group/'+group+'/reelect';
    $.get( url, function ( data ) {
        $('#spinner-modal').modal('hide');
        location.reload();
      }).fail(function () {
        $('#spinner-modal').modal('hide');
        alert('Operation failed');
      });
  });

  // edit group
  $('.btn-edit-group').click(function() {
    var group = $(this)[0].id;
    if (group == "")
      return;

    group = group.replace('edit-group-','');
    $('#edit-group-form').find('.group-name').text( group );
    $('#edit-group-oldname').val( group );
    $('#edit-group-name').val( group );
    $('#edit-group-form').modal('show');
  });

  $('#edit-group-name').keyup(function() {
    var newname = $( this ).val();
    if (newname.match(/[^\w\-_]/)) {
      formgroup = $(this).closest('.form-group');
      $( formgroup ).addClass('has-error');
      setTimeout(function(){
          $(formgroup).removeClass('has-error');
        }, 800);
      newname = newname.replace(/[^\w\-_]/g,'');
      $( this ).val( newname );
    }
  });

  $('#edit-group-form').find('.btn-primary').click(function() {
    group = $('#edit-group-oldname').val();
    newname = $('#edit-group-name').val();

    if (!newname.match(/\w[\w\-_]*\w/)) {
      $( formgroup ).addClass('has-error');
      return;
    }

    var url = "/group/"+group+"/rename";
    $('#edit-group-form').modal('hide');
    $('#spinner-modal').modal('show');
    $.get( url, { new_name: newname }, function( data) {
      $('#spinner-modal').modal('hide');
      location.reload();
    }).fail(function(){
      $('#spinner-modal').modal('hide');
      alert('Operation failed');
    });
  });
});
