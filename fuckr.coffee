window.fuckr = angular.module('fuckr', ['ngRoute', 'ngMap', 'ngStorage'])

fuckr.constant('API_URL', 'https://grindr.mobi/v3/')
fuckr.constant('API_31', 'https://grindr.mobi/v3.1/')

fuckr.config ['$httpProvider', '$routeProvider', '$compileProvider', ($httpProvider, $routeProvider, $compileProvider) ->
    $httpProvider.defaults.headers.common.Accept = '*/*' #avoids 406 error
    $httpProvider.interceptors.push ($rootScope) ->
        responseError: (response) ->
            return if response.status == -1 or response.status == 403
            addition = ""
            for i in response
                addition = addition +" "+ i +" "+ response[i]+" | ";

            message = switch
                when response.status == 0 then "Can't reach Grindr™ servers."
                when response.status >= 500 then "Grindr™ servers temporarily unavailable (HTTP #{response.status})"
                else "Err #{response.status}."
            alert(message + "+" + addition)
            $rootScope.connectionError = true
            
    for route in ['/login', '/profiles/:id?', '/chat/:id?', '/settings']
        name = route.split('/')[1]
        $routeProvider.when route,
            templateUrl: "views/#{name}.html"
            controller: "#{name}Controller"

    #whitelist chrome-extension:// href/src for nw 0.13+
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|file|mailto|chrome-extension):/)
    $compileProvider.imgSrcSanitizationWhitelist(/^\s*(https?|ftp|file|mailto|chrome-extension):/)
]

fuckr.run ['$location', '$injector', '$rootScope', '$timeout', 'authentication', ($location, $injector, $rootScope, $timeout, authentication) ->
    $rootScope.runningNodeWebkit = true
    if navigator.onLine
        #ugly: loading every factory with 'authenticated' event listener
        $injector.get(factory) for factory in ['profiles', 'chat']
        authentication.login().then(
            -> $timeout (-> $location.path('/profiles/')), 50
            -> $location.path('/login')
        )
        window.addEventListener 'offline', -> $rootScope.connectionError = true
    else
        alert('No Internet connection')
    window.addEventListener 'online', ->
        authentication.login().then ->
            $rootScope.connectionError = false
]
