# Patch Maker

> Rapidly build HTTP PATCH endpoints for you mongo-backed restful resources.

## Getting Started

Install Patch Maker:

```shell
npm install patch-maker --save
```

## Overview

Patch Maker is a PATCH submission parser builder/dsl. It allows you to quickly and concisely describe a mutable mongo-backed restful resource.  

## Examples

Build a Parser (with the help of the 'accurized' module):

```coffee
{ field } = require 'accurize'
{ patch } = require 'patch-maker'
app.patch '/types', (req, res, next) ->
  parser = patch.parser ->
    @prop 'types', ->
      @oper 'set', (types, pass, fail) ->
        return fail 'Types must be a list of strings.' unless is_array types
        return fail 'Types cannot be empty.' if is_empty types
        for type in types
          return fail 'Each type must be a string' unless is_string type
          return fail 'A type cannot be empty.' if is_empty type
        Type(req).find(name: $in: types).all (actual) ->
          return fail 'Unrecognized type(s) specified.' unless types.length is actual.length
          pass types
      @oper 'add', (types, pass, fail) ->
        for type in types
          return fail 'A type cannot be empty.' if is_empty type
        Type(req).find(name: $in: types).all (actual) ->
          return fail 'Unrecognized type(s) specified.' unless types.length is actual.length
          pass types
      @oper 'rem', (types, pass, fail) ->
        if is_empty difference(grant.types, types)
          return fail 'The update must leave the grant with at least one type.'
        pass types
  updates.parse req.body,
    (updates) ->
      Grant(req).find_and_modify _id: id_for(grant), [['_id','asc']], updates, new: true, (grant) ->
        res.json Grant.grant_for(grant, res)
    (errors) ->
      res.json 400, { errors }
```


Parse a Patch:

```coffee
 = require 'patch-maker'
parser =
```

## Contributing
In lieu of a formal style guide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality.

## Release History
_(Nothing yet)_
