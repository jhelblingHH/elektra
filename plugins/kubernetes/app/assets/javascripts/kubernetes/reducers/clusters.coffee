((app) ->
  ########################### EVENTS ##############################
  initialEventState =
    error: null
    total: 0
    offset: 0
    limit: 20
    items: []
    isFetching: false
    


  requestClusters = (state,{}) ->
    ReactHelpers.mergeObjects({},state,{
      isFetching: true
    })

  requestClustersFailure = (state,{error})->
    ReactHelpers.mergeObjects({},state,{
      isFetching: false
      error: error
    })

  receiveClusters = (state,{clusters,total})->
    ReactHelpers.mergeObjects({},state,{
      isFetching: false
      items: clusters
      error: null
    })






  # clusters reducer
  app.events = (state = initialEventState, action) ->
    switch action.type
      when app.REQUEST_CLUSTERS                     then requestClusters(state,action)

      else state

)(kubernetes)
