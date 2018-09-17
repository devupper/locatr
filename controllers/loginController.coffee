loginController = ($scope, $location, $localStorage, authentication) ->
    $scope.$storage = $localStorage
    $scope.login = ->
        $scope.logging = true
        authentication.login().then(
            -> $location.path('/profiles/')
            -> $scope.logging = $scope.$storage.email = $scope.$storage.password = null
        )
    $scope.signup = ->
        $scope.logging = true
        authentication.signup($scope.$storage.email, $scope.$storage.password, $scope.dateOfBirth).then(
            -> $location.path('/profiles/')
            -> $scope.logging = $scope.dateOfBirth = $scope.$storage.email = $scope.$storage.password = null
        )

fuckr.controller('loginController', ['$scope', '$location', '$localStorage', 'authentication', loginController])
