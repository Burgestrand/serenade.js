{Serenade} = require './serenade'
{Collection} = require './collection'
{pairToObject, serializeObject} = require './helpers'

Serenade.Properties =
  property: (name, options={}) ->
    @properties or= {}
    @properties[name] = options
    Object.defineProperty @, name,
      get: -> Serenade.Properties.get.call(this, name)
      set: (value) -> Serenade.Properties.set.call(this, name, value)
    if typeof(options.serialize) is 'string'
      @property(options.serialize, get: (-> @get(name)), set: ((v) -> @set(name, v)))

  collection: (name, options) ->
    @property name,
      get: ->
        unless @attributes[name]
          @attributes[name] = new Collection([])
          @attributes[name].bind 'change', =>
            @_triggerChangesTo(pairToObject(name, @get(name)))
        @attributes[name]
      set: (value) ->
        @get(name).update(value)

  set: (attributes, value) ->
    attributes = pairToObject(attributes, value) if typeof(attributes) is 'string'

    for name, value of attributes
      @attributes or= {}
      if @properties?[name]?.set
        @properties[name].set.call(this, value)
      else
        @attributes[name] = value
    @_triggerChangesTo(attributes)

  get: (name) ->
    @attributes or= {}
    if @properties?[name]?.get
      @properties[name].get.call(this)
    else
      @attributes[name]

  format: (name) ->
    format = @properties?[name]?.format
    if typeof(format) is 'string'
      Serenade._formats[format].call(this, @get(name))
    else if typeof(format) is 'function'
      format.call(this, @get(name))
    else
      @get(name)

  serialize: ->
    serialized = {}
    if @properties
      for name, options of @properties
        if typeof(options.serialize) is 'string'
          serialized[options.serialize] = serializeObject(@get(name))
        else if typeof(options.serialize) is 'function'
          [key, value] = options.serialize.call(@)
          serialized[key] = serializeObject(value)
        else if options.serialize
          serialized[name] = serializeObject(@get(name))
    serialized

  _triggerChangesTo: (attributes) ->
    for name, value of attributes
      @trigger?("change:#{name}", value)
      if @properties
        for propertyName, property of @properties
          if property.dependsOn
            dependencies = if typeof(property.dependsOn) is 'string' then [property.dependsOn] else property.dependsOn
            if name in dependencies
              @trigger?("change:#{propertyName}", @get(propertyName))
    @trigger?("change", attributes)
