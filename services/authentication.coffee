authentication = ($localStorage, $http, $rootScope, $q, $location, $timeout, API_URL, API_31) ->
    getGCMToken = ->
        $q (resolve, reject) ->
            if $localStorage.gcmToken
                resolve($localStorage.gcmToken)
            else
                chrome.instanceID.getToken {authorizedEntity: "1036042917246", scope: "gcm"}, (token) ->
                    $localStorage.gcmToken = token
                    resolve($localStorage.gcmToken)

    useCredentials = (data) ->
        $localStorage.authToken = data.authToken if data.authToken
        $http.defaults.headers.common['Session-Id'] = data.sessionId
        $http.defaults.headers.common['Authorization'] = "Grindr3 #{data.sessionId}"
        $rootScope.profileId = data.profileId
        $rootScope.$emit('authenticated', data.xmppToken)
        $rootScope.authenticated = true

    $rootScope.$on 'logout', ->
        $localStorage.authToken = null
        $location.path('/login')

    login: ->
        $q (resolve, reject) ->
            unless $localStorage.authToken or ($localStorage.email and $localStorage.password)
                reject('no login credentials')
                return
            getGCMToken().then (token) ->
                $http.post API_URL + 'sessions',
                    authToken: $localStorage.authToken or undefined
                    email: $localStorage.email
                    password: if !$localStorage.authToken then $localStorage.password else undefined
                    token: token
                .then (response) ->
                    if response and response.status is 200 and response.data
                        useCredentials(response.data)
                        resolve()
                    else
                        $localStorage.authToken = null
                        reject('Login error')
                , ->
                    $localStorage.authToken = null
                    reject('Login error')
                    

    signup: (email, password, dateOfBirth) ->
        $q (resolve, reject) ->
            getGCMToken().then (token) ->
                $http.post API_URL + 'users',
                    birthday: Date.parse(dateOfBirth)
                    email: email
                    password: password
                    optIn: false
                    token: token
                .success (data) -> useCredentials(data); resolve()
                .error(reject)
                    

fuckr.factory('authentication', ['$localStorage', '$http', '$rootScope', '$q', '$location', '$timeout', 'API_URL', 'API_31', authentication])
