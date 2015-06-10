class Errors

  constructor: ->
    @value = {}
    @empty = true

  add: (property, errors...) ->
    @empty = false
    unless errors.length
      errors = [ property ]
      property = 'global'
    @value[property] ?= errors: []
    @value[property].errors.push errors...

module.exports = Errors
