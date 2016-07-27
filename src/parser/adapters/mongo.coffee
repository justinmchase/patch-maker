{ curry, find, identity, isArray, isPlainObject, isString } = require 'lodash'
Operator = require '../operator'

to_object = (value, keys) ->
  return null unless isString(keys) or isArray(keys)
  updates = {}
  updates[key] = value for key in ([].concat keys)
  updates

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

module.exports = {

  operator_for: (operation) ->
    find operators, (operator) ->
      operator.matches(operation)

  adapt: identity

}
