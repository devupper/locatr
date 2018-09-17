#Grindr™ chat messages are JSON objects sent and received with XMPP:
#   addresses: "{profileId}@chat.grindr.com"
#   password: one-time token (see authentication)
#Grindr™ chat uses HTTP to:
#   - get messages sent while you were offline (/undeliveredChatMessages)
#   - confirm receiption (/confirmChatMessagesDelivered)
#   - notify Grindr™ you blocked someone (managed by profiles controller)
jacasr = require('jacasr')
nwWindow = gui = require('nw.gui').Window.get()

chat = ($http, $localStorage, $rootScope, $q, profiles, authentication, API_URL) ->
    s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    uuid = -> "#{s4()}#{s4()}-#{s4()}-#{s4()}-#{s4()}-#{s4()}#{s4()}#{s4()}".toUpperCase()

    client = {}

    $localStorage.conversations = $localStorage.conversations || {}
    $localStorage.sentImages = $localStorage.sentImages || []

    createConversation = (id) ->
        $localStorage.conversations[id] =
            id: id
            messages: []
        profiles.get(id).then (profile) ->
            $localStorage.conversations[id].thumbnail = profile.profileImageMediaHash


    addMessage = (message) ->
        if message.sourceProfileId == $rootScope.profileId
            fromMe = true
            id = message.targetProfileId
        else
            fromMe = false
            id = message.sourceProfileId

        return if profiles.isBlocked(id)

        if message.type == 'block'
            delete $localStorage.conversations[id]
            if fromMe then profiles.block(id) else profiles.blockedBy(id)
        else
            createConversation(id) unless $localStorage.conversations[id]
            timestamp = message.timestamp
            $localStorage.conversations[id].lastTimeActive = timestamp
            message = switch message.type
                when 'text' then {text: message.body}
                when 'map' then {location: angular.fromJson(message.body)}
                when 'image' then {image: angular.fromJson(message.body).imageHash}
                else {text: message.type + ' ' + message.body}
            message.fromMe = fromMe
            message.timestamp = timestamp
            $localStorage.conversations[id].messages.push(message)
            unless fromMe
                $localStorage.conversations[id].unread = true
                document.getElementById('notification').play()
            
        $rootScope.$broadcast('new_message')


    acknowledgeMessages = (messageIds) ->
        $http.put(API_URL + 'me/chat/messages?confirmed=true', {messageIds: messageIds})
    
    lastConnection = null
    $rootScope.$on 'authenticated', (event, token) ->
        lastConnection ||= Date.now()
        loggingOut = false
        client = new jacasr.Client
            login: $rootScope.profileId
            password: token
            domain: 'chat.grindr.com'

        client.on 'ready', ->
            chat.connected = true
            $http.get(API_URL + 'me/chat/messages?undelivered=true').then (response) ->
                messageIds = []
                _(response.data.messages).sortBy((message) -> message.timestamp).forEach (message) ->
                    addMessage(message)
                    messageIds.push(message.messageId)
                if messageIds.length > 0
                    acknowledgeMessages(messageIds)

        client.on 'message', (_, json) ->
            message = angular.fromJson(json)
            addMessage(message)

        client.on 'close', ->
            now = Date.now()
            return if loggingOut
            if (now - lastConnection) < 60000
                $rootScope.chatError = true
                alert("XMPP chat error. If you're using public wifi, XMPP protocol is probably blocked.")
            else
                lastConnection = now
                client.disconnect()
                authentication.login()

        $rootScope.$on 'logout', ->
            loggingOut = true
            client.disconnect()

        window.onbeforeunload = ->
          client.disconnect()

        nwWindow.on 'close', ->
          client.disconnect()
          this.close(true)

    sendMessage = (type, body, to, save=true) ->
        message =
            targetProfileId: String(to)
            type: type
            messageId: uuid()
            timestamp: Date.now()
            sourceDisplayName: ''
            sourceProfileId: String($rootScope.profileId)
            body: body
        client.write """<message from='#{$rootScope.profileId}@chat.grindr.com/jacasr' to='#{to}@chat.grindr.com' xml:lang='' type='chat' id='#{message.messageId}'><body>#{_.escape angular.toJson(message)}</body><markable xmlns='urn:xmpp:chat-markers:0'/></message>"""
        #TODO: send read message confirmation
        
        
        addMessage(message) if save

    return {
        sendText: (text, to, save=true) ->
            sendMessage('text', text, to, save)

        getConversation: (id) ->
            $localStorage.conversations[id]
        lastestConversations: ->
            _.sortBy $localStorage.conversations, (conversation) -> - conversation.lastTimeActive
        
        sentImages: $localStorage.sentImages
        sendImage: (imageHash, to) ->
            messageBody = angular.toJson({imageHash: imageHash})
            sendMessage('image', messageBody, to)

        sendLocation: (to) ->
            messageBody = angular.toJson
                lat: $localStorage.location.lat
                lon: $localStorage.location.lon
            sendMessage('map', messageBody, to)

        block: (id) ->
            sendMessage('block', null, id)
        delete: (id) ->
            delete $localStorage.conversations[id]
    }


fuckr.factory('chat', ['$http', '$localStorage', '$rootScope', '$q', 'profiles', 'authentication', 'API_URL', chat])
