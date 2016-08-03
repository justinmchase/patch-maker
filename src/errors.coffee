class Errors

  constructor: ->
    @value = {}
    @empty = true

  add: (property, errors...) ->
    @empty = false
    [ property, errors ] = [ 'global', [ property ] ] unless errors.length
    @value[property] ?= errors: []
    @value[property].errors.push errors...

module.exports = Errors
