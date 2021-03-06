{ assign, find, isEmpty, isString } = require 'lodash'
{ eachSeries } = require 'async'
Errors = require '../errors'
adapters = require './adapters'

class Property

  constructor: (@name, supported...) ->
    @pattern = new RegExp("^#{@name}".replace(/\./g, '\\.').replace(/\*/g, '\\d+') + '$')
    @supported = {}
    @oper(operator) for operator in supported

  oper: (operator, validator) ->
    validator ?= (args..., pass, fail) -> pass args...
    @supported[operator] = validator
    @

  matches: (name) ->
    @pattern.test name

  validator: (operator) ->
    @supported[operator.name] ? (args, pass, fail) =>
      fail "The '#{@name}' property does not support the '#{operator.name}' operation."

  validate: (operator, args, pass, fail) ->
    args = [].concat args if operator.plural
    @validator(operator)(args, pass, fail)


class Parser

  constructor: (@adapter, @properties=[]) ->

  prop: (name, operations..., configurator) ->
    if isString configurator
      operations.push configurator
      configurator = null
    property = new Property(name, operations...)
    @properties.push property
    configurator?.apply property, [ property ]
    property

  parse: (operations, success, failure) =>
    updates = {}
    errors = new Errors()
    changed = {}
    eachSeries ([operation, arg] for operation, arg of operations),
      ([operation, arg], next) =>
        operator = @adapter.operator_for(operation)
        unless operator?
          errors.add "Invalid operation: '#{operation}' specified."
          return next()
        args = operator.transform arg
        unless args?
          errors.add "Malformed arguments specified for operation: '#{operation}'."
          return next()
        if isEmpty args
          errors.add "No arguments specified for operation: '#{operation}'."
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
            property.validate operator, arg[prop],
              (value) ->
                arg[prop] = value
                next()
              (errs...) ->
                errors.add prop, error for error in errs
                next()
          () ->
            updates["$#{operator.canonical}"] = assign(updates["$#{operator.canonical}"] ? {}, operator.transform arg)
            next()
      () =>
        for prop, count of changed
          errors.add prop, "Multiple operations attempted on property '#{prop}'." if count > 1
        if errors.empty then success(@adapter.adapt(updates)) else failure(errors.value)

module.exports = (adapter, configurator) ->
  [ configurator, adapter ] = [ adapter, 'mongo' ] unless configurator
  parser = new Parser(adapters[adapter] || adapter)
  configurator.apply parser, [ parser ]
  parser
