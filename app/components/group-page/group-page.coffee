module.exports = 
  url: '/groups/:groupId'
  template: require('./group-page.html')
  controller: ($scope, Records, $stateParams, $location, CurrentUser, $window, ipCookie, AuthenticateUser) ->
    $scope.contributionsLoaded = $scope.commentsLoaded = $scope.membershipsLoaded = false

    AuthenticateUser().then ->
      groupId = parseInt($stateParams.groupId)
      ipCookie('currentGroupId', groupId)
      $scope.currentUserId = CurrentUser().id
      
      Records.groups.findOrFetchById(groupId).then (group) ->
        $scope.group = group
        $scope.currentMembership = group.membershipFor(CurrentUser())
        Records.buckets.fetchByGroupId(group.id).then (data) ->
          if data.buckets.length > 0
            _.each data.buckets, (bucket) ->
              Records.contributions.fetchByBucketId(bucket.id).then ->
                $scope.contributionsLoaded = true
              Records.comments.fetchByBucketId(bucket.id).then ->
                $scope.commentsLoaded = true
          else 
            $scope.contributionsLoaded = $scope.commentsLoaded = true
        Records.memberships.fetchByGroupId(group.id).then ->
          $scope.membershipsLoaded = true

    $scope.createBucket = ->
      $location.path("/buckets/new")

    $scope.showBucket = (bucketId) ->
      $location.path("/buckets/#{bucketId}")

    $scope.selectTab = (tabNum) ->
      $scope.tabSelected = parseInt tabNum

    $scope.openAdminPanel = ->
      $location.path("/admin")

    $scope.openFeedbackForm = ->
      $window.location.href = 'https://docs.google.com/forms/d/1-_zDQzdMmq_WndQn2bPUEW2DZQSvjl7nIJ6YkvUcp0I/viewform?usp=send_form';

    return