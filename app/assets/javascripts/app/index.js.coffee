$(document).ready ->
  $navigation = $('#report_navigation')
  $editables  = $()

  directives =
    profiles:
      name:
        href: -> @url
      testsets:
        name:
          href: -> @url
        compare:
          href: (params) -> if @comparison_url then @comparison_url else $(params.element).hide(); return ""
        'inplace-edit':
          'data-url': -> @url
        products:
          name:
            href: -> @url
          'inplace-edit':
            'data-url': -> @url

  undo = (input) ->
    $input = $(input)
    $editables.text $input.data('undo')

  edit = (event) ->
    event.preventDefault()
    $link = $(this)
    $link.hide()
    $link.next('input.inplace-edit').show().focus().val($link.text())
                                                   .data('undo', $link.text())

    $editables = $('.products a').filter(-> $(this).text() == $link.text()).add $link
    $editables.addClass 'being_edited'

  end_edit = (input) ->
    $input = $(input)
    $input.hide()
    $input.prev('a.name').show()
    $editables.removeClass 'being_edited'
    $editables = $()

  cancel = (input) ->
    undo input
    end_edit input

  submit = (input) ->
    save input
    end_edit input

  save = (input) ->
    $input   = $(input)
    post_url = $input.attr('data-url')
    val  = $input.val()

    data =
      "authenticity_token" : auth_token
      "_method"            : "put"
      "new_value"          : val

    $.post post_url, data, (res, status) ->
      [_, release, scope] = location.hash.split '/'
      $.get "/#{release}/categories.json?scope=#{scope}", (view_model) ->
        $navigation.render(view_model, directives).show()
        editMode()

  editMode = (event) ->
    event?.preventDefault()
    $('#index_page').addClass 'editing'
    $navigation.find('tbody a.name').addClass('editable_text').show()
    $navigation.find('a.compare').hide()

  viewMode = (event) ->
    event.preventDefault()
    $('#index_page').removeClass 'editing'
    $navigation.find('tbody a.name').removeClass 'editable_text'
    $navigation.find('tbody a.name').show()
    $navigation.find('a.compare').filter((index) -> $(this).attr('href').length > 0).show()

  initInplaceEdit = ->
    # View mode / Edit mode
    $('#home_edit_link').click editMode
    $('#home_edit_done_link').click viewMode

    # Edit events
    $('#index_page.editing #report_navigation tbody a.name').live 'click', edit
    $inputs = $navigation.find 'input.inplace-edit'
    $inputs.live 'blur',        -> cancel this
    $inputs.live 'keyup', (key) -> cancel this if (key.keyCode == 27) # esc
    $inputs.live 'keyup', (key) -> submit this if (key.keyCode == 13) # enter

    # Update text in links
    $('input.inplace-edit').live 'keyup', -> $editables.text $(this).val()

     # Hover hilight for products
    product_titles = '#index_page.editing .products a'
    $(product_titles).live 'mouseover', ->
      if $editables.length == 0
        product_name = $(this).text()
        $(product_titles).filter(-> $(this).text() == product_name)
          .addClass('to_be_edited')

    $(product_titles).live 'mouseout', ->
      $(product_titles).removeClass('to_be_edited')

  initTabs = ->
    $('.tabs').click (event) ->
      event.preventDefault()
      $(this).attr('data-selected', $(event.target).attr 'href').change()

    $('.tabs').change (event) ->
      release_path = $('#release_filters').attr 'data-selected'
      scope_path   = $('#report_filters').attr 'data-selected'
      Spine.Route.navigate release_path + scope_path

    [_, release, scope] = location.hash.split '/'
    if release and scope
      $("#release_filters a[href='/#{release}']").click()
      $("#report_filters a[href='/#{scope}']").click()
    else
      # On staging set better defaults (current data set is quite old)
      if location.hostname == 'qa-reports.qa.leonidasoy.fi'
        $("#release_filters a[href='/1.2']").click()
        $("#report_filters a[href='/all']").click()
      else
        $("#release_filters .current a").click()
        $("#report_filters .current a").click()

  Spine.Route.add "/:release/:scope": (params) ->
    $.get "/#{params.release}/categories.json?scope=#{params.scope}", (view_model) ->
      # Set active tab
      $.merge($('a[href="/' + params.scope + '"]', '#report_filters'),
              $('a[href="/' + params.release + '"]', '#release_filters')).parent().addClass('current').siblings().removeClass('current').end()
      $navigation.render(view_model, directives).show()

  Spine.Route.setup()

  initInplaceEdit()
  initTabs()
