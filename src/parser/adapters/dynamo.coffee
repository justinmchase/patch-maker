{ assign, find, identity, isArray, isPlainObject, isString } = require 'lodash'
Operator = require '../operator'

to_object = (auto) -> (entries, transform=identity) ->
  return null unless isString(entries) or isArray(entries) or isPlainObject(entries)
  updates = {}
  for entry in ([].concat entries)
    if isString(entry)
      updates[entry] = transform entry, auto
    else
      for key, value of entry
        updates[key] = transform key, value
  updates

to_array = (entries) ->
  [].concat entries

to_arrays = (entries, transform=identity) ->
  return null unless isPlainObject entries
  updates = {}
  updates[key] = transform [].concat(value), key for key, value of entries
  updates

attr = (key) ->
  result = {}
  result["##{key}"] = key.replace /\.(\d+)/g, '[$1]'
  result

val = (key, value) ->
  result = {}
  result[":#{key}"] = value
  result

operators = [
  new Operator 'set', false, []
  new Operator 'del', false, [ 'delete' ], to_object 1
  new Operator 'inc', false, [ 'increment' ], to_object 1
  new Operator 'dec', false, [ 'decrement' ], to_object 1
  new Operator 'add', true, [], to_arrays
  new Operator 'rem', true, [ 'remove' ], to_arrays
  new Operator 'enq', true, [ 'enqueue' ], to_arrays
  new Operator 'deq', false, [ 'dequeue' ], to_object 1
]

adaptations =
  set:
    action: 'SET'
    adapt: (entries) ->
      {
        expression: "##{key} = :#{key}"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  del:
    action: 'REMOVE'
    adapt: (entries) ->
      {
        expression: "##{key}"
        attribute: attr key
      } for key, value of entries
  inc:
    action: 'SET'
    adapt: (entries) ->
      {
        expression: "##{key} + :#{key}"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  dec:
    action: 'SET'
    adapt: (entries) ->
      {
        expression: "##{key} - :#{key}"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  add:
    action: 'ADD'
    adapt: (entries) ->
      {
        expression: "##{key} :#{key}"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  rem:
    action: 'DELETE'
    adapt: (entries) ->
      {
        expression: "##{key} :#{key}"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  enq:
    action: 'SET'
    adapt: (entries) ->
      {
        expression: "##{key} = list_append(##{key}, :#{key})"
        attribute: attr key
        value: val key, value
      } for key, value of entries
  deq:
    action: 'REMOVE'
    adapt: (entries) ->
      {
        expression: "##{key}"
        attribute: attr "#{key}.0"
      } for key, value of entries

adapt = (updates) ->
  console.json updates
  actions = {}
  attributes = {}
  values = {}
  for oper, entries of updates
    adapter = adaptations[oper[1..]]
    for adapted in adapter.adapt entries
      (actions[adapter.action] ?= []).push adapted.expression
      assign(attributes, adapted.attribute)
      assign(values, adapted.value)
  actions[action] = expressions.join ', ' for action, expressions of actions
  {
    UpdateExpression: ([ action, expressions ].join ' ' for action, expressions of actions).join("\n")
    ExpressionAttributeNames: attributes,
    ExpressionAttributeValues: values
  }

module.exports = {

  operator_for: (operation) ->
    find operators, (operator) ->
      operator.matches(operation)

  adapt

}
