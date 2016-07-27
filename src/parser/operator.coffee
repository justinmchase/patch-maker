{ identity, isFunction } = require 'lodash'

class Operator

  constructor: (@name, @plural, @aliases, @canonical, @transform=identity) ->
    if isFunction @canonical
      @transform = @canonical
      @canonical = undefined
    @canonical ?= @name

  matches: (name) ->
    name[1..] is @name or name[1..] in @aliases

module.exports = Operator
