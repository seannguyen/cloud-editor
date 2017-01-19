# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

(()->
  window.note = {
    onSaveButtonClick: (url) ->
      $("#note-save-button").attr("disabled", true)
      $('#note-notification-tick-loading').fadeIn()
      $.ajax({
        url: url,
        method: 'PUT',
        data: {
          content: $('#note-content').val()
        }
      }).done((data) ->
        $('#note-notification-tick-loading').fadeOut(100, () ->
          $('#note-notification-tick-success').fadeIn(100, () ->
            setTimeout(() ->
              $('#note-notification-tick-success').fadeOut()
            , 1000)
          )
        )
      ).fail((err) ->
        $('#note-alert').fadeIn()
        $('#note-alert > p').html(err.message || 'Oop! cannot save')
      )
    
    onAlertCloseButtonClick: () ->
      $('#note-alert').fadeOut()
    
    onContentChange: () ->
      $("#note-save-button").removeAttr("disabled")
  }
)()
  