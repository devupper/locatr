fuckr.factory 'uploadImage', ['$http', '$q', ($http, $q) ->
    uploadImage = (file, urlFunction) ->
        deferred = $q.defer()
        #dirty vanilla JS trick to figure out dimensions
        img = new Image
        img.src = URL.createObjectURL(file)
        img.onload = ->
            $http
                method: "POST"
                url: urlFunction(img.width, img.height)
                data: file
                headers:
                    'Content-Type': file.type
            .then (response) ->
                deferred.resolve(response.data.mediaHash)
        deferred.promise
    
    uploadChatImage: (file) ->
        uploadImage file, (width, height) ->
            'https://g3-beta-upload.grindr.com/v3/me/pics?type=chat'

    uploadProfileImage: (file) ->
        uploadImage file, (width, height) ->
            squareSize = _.min([width, height])
            #*Image/MaxY,MinX,MaxX,MinY of the crop
            "https://g3-beta-upload.grindr.com/v3/me/pics?type=profile&thumbCoords=#{squareSize},0,#{squareSize},0"
]
