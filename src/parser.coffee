{ find, isArray, isString, isPlainObject, isFunction, extend, compact, flatten, identity, object, curry } = require 'lodash'
{ eachSeries } = require 'async'
Errors = require './errors'

to_object = (value, keys) ->
  return null unless isString(keys) or isArray(keys)
  keys = [].concat keys
  object keys, (value for key in keys)

to_array = (props) ->
  return null unless isPlainObject props
  updates = {};
  updates[prop] = [].concat value for prop, value of props
  updates

to_each = (props) ->
  return null unless isPlainObject props
  updates = {};
  updates[prop] = { $each: [].concat value } for prop, value of props
  updates

class Operator

  constructor: (@name, @plural, @aliases, @canonical, @transform=identity) ->
    if isFunction @canonical
      @transform = @canonical
      @canonical = undefined
    @canonical ?= @name

  matches: (name) ->
    name[1..] == @name or name[1..] in @aliases

operators = [
  new Operator 'set', false, []
  new Operator 'del', false, [ 'delete'], 'unset', curry(to_object)(1)
  new Operator 'inc', false, [ 'increment' ], curry(to_object)(1)
  new Operator 'add', true, [], 'addToSet', to_each
  new Operator 'rem', true, [ 'remove' ], 'pullAll', to_array
  new Operator 'push', true, [ 'enq', 'enqueue' ], 'pushAll', to_array
  new Operator 'pop', false, [], curry(to_object)(1)
  new Operator 'deq', false, [ 'dequeue' ], 'pop', curry(to_object)(-1)
]


class Property

  constructor: (@name, supported...) ->
    @pattern = new RegExp("^#{@name}".replace('.', "\\.").replace(/\*$/, '.+') + '$')
    @supported = {}
    @oper(operator) for operator in supported

  oper: (operator, validator) ->
    validator ?= (args..., pass, fail) -> pass()
    @supported[operator] = validator
    @

  matches: (name) ->
    @pattern.test name

  validator: (operator) ->
    @supported[operator.name] ? (args..., pass, fail) =>
      fail "The '#{@name}' property does not support the '#{operator.name}' operation."

  validate: (operator, args..., pass, fail) ->
    @validator(operator)(args..., pass, fail)


class Parser

  constructor: (@properties=[]) ->

  prop: (name, operations..., configurator) ->
    if isString configurator
      operations.push configurator
      configurator = null
    property = new Property(name, operations...)
    @properties.push property
    configurator?.apply property
    property

  parse: (operations, success, failure) =>
    updates = {}
    errors = new Errors()
    changed = {}
    eachSeries ([operation, arg] for operation, arg of operations),
      ([operation, arg], next) =>
        operator = find operators, (operator) =>
          operator.matches(operation)
        unless operator?
          errors.add "Invalid operation: '#{operation}' specified."
          return next()
        args = operator.transform arg
        unless args?
          errors.add "Malformed arguments specified for operation: '#{operation}'."
          return next()
        eachSeries ([prop, value] for prop, value of args),
          ([prop, value], next) =>
            property = find @properties, (property) ->
              property.matches(prop)
            unless property?
              errors.add prop, "Unmodifiable property: '#{prop}' specified."
              return next()
            changed[prop] ?= 0
            changed[prop]++
            hargs = compact [arg[prop]]
            hargs = flatten(hargs, true) if operator.plural
            property.validate operator, hargs...,
              (value) ->
                arg[prop] = value
                next()
              (errs...) ->
                errors.add prop, error for error in errs
                next()
          () ->
            updates["$#{operator.canonical}"] = extend(updates["$#{operator.canonical}"] || {}, operator.transform arg)
            next()
      () ->
        for prop, count of changed
          errors.add prop, "Multiple operations attempted on property '#{prop}'." if count > 1
        if errors.empty then success(updates) else failure(errors.value)

module.exports = (configurator) ->
  parser = new Parser()
  configurator.apply parser
  parser
