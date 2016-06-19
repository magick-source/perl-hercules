jQuery(document).ready(function($) {

  $('button').tooltip();

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
    var maxname = "#max-jobs-"+group;
    var max = $( maxname ).text();
    max = max.replace(/[^0-9]/g, '');

    $('#edit-group-form').find('.group-name').text( group );
    $('#edit-group-oldname').val( group );
    $('#edit-group-name').val( group );
    $('#edit-group-max-jobs').val( max );
    $('#edit-group-form').modal('show');
  });

  $('#add-new-group').click(function() {
    $('#edit-group-form').find('.group-name').text( 'NewGroup' );
    $('#edit-group-oldname').val( '' );
    $('#edit-group-name').val( 'NewGroup' );
    $('#edit-group-max-jobs').val( 1 );
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
  $('#edit-group-max-jobs').keyup(function() {
    var max = $( this ).val();
    if (max.match(/[^0-9]/)) {
      formgroup = $(this).closest('.form-group');
      $( formgroup ).addClass('has-error');
      setTimeout(function(){
          $(formgroup).removeClass('has-error');
        }, 800);
      max = max.replace(/[^0-9]/g,'');
      $( this ).val( newname );
    }
  });


  $('#edit-group-form').find('.btn-primary').click(function() {
    group = $('#edit-group-oldname').val();

    newname = $('#edit-group-name').val();
    if (!newname.match(/^\w[\w\-_]*\w$/)) {
      formgroup = $('#edit-group-name').closest('.form-group');
      $( formgroup ).addClass('has-error');
      return;
    }

    max = $('#edit-group-max-jobs').val();
    if (!max.match(/^[0-9]+$/)) {
      formgroup = $('#edit-group-max-jobs').closest('.form-group');
      $( formgroup ).addClass('has-error');
      return;
    }

    var url;
    if (group) {
      url = "/group/"+group+"/change";
    } else {
      url = '/group/new';
    }
    $('#edit-group-form').modal('hide');
    $('#spinner-modal').modal('show');
    $.get( url, { new_name: newname, max_jobs: max }, function(data) {
      $('#spinner-modal').modal('hide');
      location.reload();
    }).fail(function(){
      $('#spinner-modal').modal('hide');
      alert('Operation failed');
    });
  });
  
  // list jobs in group
  $('.btn-list-jobs').click(function() {
    var group = $(this)[0].id;
    if (group == "")
      return;

    group = group.replace('list-jobs-','');

    location.href = '/jobs/'+group;
  });

  // start job
  $('.btn-start-job,.btn-retry-job').click(function() {
    var job=$(this)[0].id;
    if (job == '')
      return;

    job = job.match(/start-job/)
        ? job.replace('start-job-','')
        : job.replace('retry-job-','');
    url = '/job/'+job+'/start';
    $('#spinner-modal').modal('show');
    $.get(url, function(data) {
      $('#spinner-modal').modal('hide');
      location.reload();
    }).fail(function() {
      $('#spinner-modal').modal('hide');
      alert('Operation failed');
    });
  });

  // stop job
  $('.btn-stop-job').click(function() {
    var job=$(this)[0].id;
    if (job == '')
      return;

    job = job.replace('stop-job-','');
    url = '/job/'+job+'/stop';
    $('#spinner-modal').modal('show');
    $.get(url, function(data) {
      $('#spinner-modal').modal('hide');
      location.reload();
    }).fail(function() {
      $('#spinner-modal').modal('hide');
      alert('Operation failed');
    });
  });

  $('.btn-view-job').click(function() {
    var job=$(this)[0].id;
    if (job == '')
      return;

    job = job.replace('view-job-','');
    if (job == '')
      return;

    url = '/job/'+job;
    location.href = url;
  });

  // edit job
  $('.btn-edit-job').click(function() {
    var job=$(this)[0].id;
    if (job == '')
      return;

    job = job.replace('edit-job-','');
    if (job == '')
      return;

    url = '/job/'+job+'/edit';
    location.href = url;
  });

  $('.btn-go-back').click(function() {
    history.back();
  });
});
