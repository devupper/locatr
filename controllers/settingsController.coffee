settingsController = ($scope, $http, $localStorage, profiles, uploadImage, API_URL) ->
    $scope.$storage = $localStorage
    $scope.$storage.localUnits ||= if navigator.locale == 'en-US' then 'US' else 'metric'

    $scope.profile = {}
    profiles.get($scope.profileId).then (profile) ->
        $scope.profile = profile

    $scope.updateAttribute = (attribute) ->
        data = {}
        data[attribute] = $scope.profile[attribute]
        unless data == {}
            $http.put(API_URL + 'me/profile', data)

    $scope.deleteProfile = ->
        if confirm("Sure you want to delete your profile")
            $http.delete(API_URL + 'me/profile').then ->
                $scope.logoutAndRestart()

    $scope.$watch 'imageFile', ->
        if $scope.imageFile
            $scope.uploading = true
            uploadImage.uploadProfileImage($scope.imageFile).then(
                -> alert("Image up for review by some Grindr™ monkey")
                -> alert("Image upload failed")
            ).finally -> $scope.uploading = false

weightInput = ->
    restrict: 'A'
    require: 'ngModel'
    link: (scope, element, attributes, ngModel) ->
        ngModel.$formatters.push (gramsInput) -> gramsInput / 1000
        ngModel.$parsers.push (kgInput) -> kgInput * 1000

fuckr
    .controller('settingsController', ['$scope', '$http', '$localStorage', 'profiles', 'uploadImage', 'API_URL', settingsController])
    .directive('weightInput', weightInput)
