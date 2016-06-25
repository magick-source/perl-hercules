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

  $('#edit-job-name').keyup(function() {
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

  $('#add-new-job').click(function() {
    url = '/job/new';
    location.href = url;
  });

  // Save job edit
  $('.btn-save-job-changes').click(function() {
    var data = {};
    data.name = $('#edit-job-name').val();
    var errors = 0;
    formgroup = $('#edit-job-name').closest('.form-group');
    $(formgroup).removeClass('has-error');
    if (data.name == '' || data.name.match(/[^\w\-_]/)) {
      $( formgroup ).addClass('has-error');
      errors++;
    }

    // cron group
    data.cron_group = $('#edit-job-crongroup option:selected').val();

    // class
    var useclass=$('[name=useclass]:checked').val();
    console.log('useclass: '+useclass);
    var usegroup = $('#edit-group-core_class').closest('.form-group');
    $(usegroup).removeClass('has-error');
    if (useclass == '' ) {
      $(usegroup).addClass('has-error');
      errors++; 
    } else if (useclass == 'core') {
      data.jobclass = $('#edit-group-core_class').val();
      if (data.jobclass == '') {
        $(usegroup).addClass('has-error');
        errors++;
      }
    } else if (useclass == 'nocore') {
      data.jobclass = $('#edit-job-class').val();
      if (data.jobclass == '') {
        $(usegroup).addClass('has-error');
        errors++;
      }
    }
    if (data.jobclass != '') {
      if (!data.jobclass.match(/^\w+(::\w+)*(::)?$/)) {
        $(usegroup).addClass('has-error');
        errors++;
      }
    }

    // params
    var params = $('#edit-job-params').val();
    $('#edit-job-params').closest('.form-group').removeClass('has-error');
    if (params != '') {
      var paramjson = '{'+params+'}';
      try {
        paramobj = JSON.parse( paramjson );
        data.params = params;
      } catch(e) {
        $('#edit-job-params').closest('.form-group').addClass('has-error'); 
        errors++;
      }
    }

    //run schedule
    var usesched=$('[name=runtype]:checked').val();
    var schdgroup=$('#edit-job-run-every').closest('.form-group');
    $(schdgroup).removeClass('has-error');
    if (usesched == '') {
      $(schdgroup).addClass('has-error');
      errors++;
    } else if ( usesched == 'every') {
      data.every = $('#edit-job-run-every').val();
      if (data.every == '') {
        $(schdgroup).addClass('has-error');
        errors++;

      } else if (!data.every.match(/^\d+[smhdwMy]?$/)) {
        $(schdgroup).addClass('has-error');
        errors++;
      }
    } else if ( usesched == 'cron' ) {
      data.cron = $('#edit-job-run-cron').val();
      if ( data.cron == '' ) {
        $(schdgroup).addClass('has-error');
        errors++;
        
      } else {
        var parts = data.cron.split(' ');
        if ( parts.length != 5 ) {
          $(schdgroup).addClass('has-error');
          errors++;
        } else {
          for (i=0; i < parts.length; i++) {
            if (!parts[i].match(/^(\*(\/\d+)?|\d+(,\d+)*)$/)) {
              $(schdgroup).addClass('has-error');
              errors++;
            }
          }
        }
      }
    }
    
    if ( errors === 0 ) {
      var url;
      var oldname = $('#edit-job-old-name').val();
      if ( oldname ) {
        url = '/job/'+oldname+'/save/';
      } else {
        url = '/job/add';
      }
      $('#spinner-modal').modal('show');
      $.post(url, data, function( res ) {
          $('#spinner-modal').modal('hide');
          url = '/job/'+data.name;
          location.href = url;
        }).fail(function() {
          $('#spinner-modal').modal('hide');
          alert('Operation failed');
        });
    }
  });
});
