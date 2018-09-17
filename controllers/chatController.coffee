chatController = ($scope, $routeParams, chat, uploadImage) ->
    $scope.lastestConversations = chat.lastestConversations()

    $scope.open = (id) ->
        $scope.conversationId = id
        $scope.conversation = chat.getConversation(id)
        $scope.conversation.unread = false if $scope.conversation
        $scope.sentImages = null
    $scope.open($routeParams.id) if $routeParams.id

    $scope.$on 'new_message', ->
        if $scope.conversationId
            $scope.conversation = chat.getConversation($scope.conversationId)
            $scope.conversation.unread = false if $scope.conversation
        $scope.lastestConversations = chat.lastestConversations()
        $scope.$apply()

    $scope.sendText = ->
        if $scope.message
            chat.sendText($scope.message, $scope.conversationId)
            $scope.message = ''

    $scope.showSentImages = ->
        $scope.sentImages = chat.sentImages

    $scope.clearSentImages = ->
        if window.confirm("Sure you want to delete all saved images?")
            chat.sentImages.splice(0, chat.sentImages.length)
    
    $scope.$watch 'imageFile', ->
        if $scope.imageFile
            $scope.uploading = true
            uploadImage.uploadChatImage($scope.imageFile).then (imageHash) ->
                $scope.uploading = false
                chat.sentImages.push(imageHash) if imageHash

    $scope.sendImage = (imageHash) ->
        chat.sendImage(imageHash, $scope.conversationId)
        
    $scope.sendLocation = ->
        chat.sendLocation($scope.conversationId)

    $scope.block = ->
        if confirm('Sure you want to block him?')
            chat.block($scope.conversationId)
            $scope.conversationId = null
            $scope.lastestConversations = chat.lastestConversations()

    $scope.delete = ->
        if confirm('Sure you want to delete this conversation?')
            chat.delete($scope.conversationId)
            $scope.conversationId = null
            $scope.lastestConversations = chat.lastestConversations()

    clipboard = require('nw.gui').Clipboard.get()
    $scope.copyToClipboard = ->
        text = $scope.conversation.messages
            .map (message) ->
                if message.text
                    message.text
                else if message.image
                    "http://cdns.grindr.com/grindr/chat/#{message.image}"
                else if message.location
                    "https://maps.google.com/?q=loc:#{message.location.lat},#{message.location.lon}"
            .join('\n\n')
        clipboard.set(text)

onEnter = ($parse) ->
    restrict: 'A'
    link: (scope, element, attrs) ->
        [shiftDown, SHIFT, ENTER] = [false, 16, 13]
        callback = $parse(attrs.onEnter, null, true)
        element.bind 'keyup', (event) -> shiftDown = false if event.which is SHIFT
        element.bind 'keydown', (event) ->
            if event.which is SHIFT
                shiftDown = true
            else if event.which is ENTER and not shiftDown
                scope.$apply -> callback(scope)
                event.preventDefault()

scrollDownOnNewConversation = ->
    restrict: 'A'
    link: (scope, element) ->
        scope.$watch 'conversationId', (value) ->
            if value
                setTimeout (-> element[0].scrollTop = 100000), 100

fuckr
    .controller('chatController', ['$scope', '$routeParams', 'chat', 'uploadImage', chatController])
    .directive('onEnter', onEnter)
    .directive('scrollDownOnNewConversation', scrollDownOnNewConversation)
