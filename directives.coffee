fuckr.directive 'nonDraggable', ->
    restrict: 'A'
    link: (_, element) ->
        element.bind 'dragstart', (event) -> event.preventDefault()

fuckr.directive 'emoji', ->
    runningOnMac = typeof process isnt 'undefined' and process.platform is 'darwin'
    useOpenSansEmoji = (_, element) -> element.css({'font-family', 'sans-serif, OpenSansEmoji'})
    restrict: 'A'
    link: if runningOnMac then _.noop else useOpenSansEmoji

fuckr.directive 'highResSrc', ->
    restrict: 'A'
    link: (scope, element, attrs) ->
      element.bind 'load', ->
          angular.element(this).attr("src", attrs.highResSrc)

fuckr.directive 'fileModel', ['$parse', ($parse) ->
    restrict: 'A'
    link: (scope, element, attrs) ->
        model = $parse(attrs.fileModel)
        modelSetter = model.assign
        element.bind 'change', ->
            scope.$apply ->
                if element[0].files.length > 1
                    modelSetter scope, element[0].files
                else
                    modelSetter scope, element[0].files[0]
]

if typeof process != 'undefined' and process.versions['node-webkit']
    fuckr.directive 'target', ->
        gui = require 'nw.gui'
        window.open = (url, target) ->
            gui.Shell.openExternal(url) if target is '_blank'
        restrict: 'A'
        scope:
            target: '@'
            href: '@'
        link: ($scope, $element) ->
            if $scope.target is '_blank'
                $element.bind 'click', (event) ->
                    event.preventDefault()
                    gui.Shell.openExternal $scope.href
