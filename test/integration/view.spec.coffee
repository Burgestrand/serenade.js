require './../spec_helper'
{expect} = require('chai')
{Serenade} = require '../../src/serenade'

describe 'View', ->
  beforeEach ->
    @setupDom()

  it 'compiles a view instruction by fetching and compiling the given view', ->
    Serenade.view('test', 'li[id="foo"]')
    @render '''
      ul
        - view "test"
    '''
    expect(@body).to.have.element('ul > li#foo')

  it 'changes controller in view', ->
    funked = false
    class TestCon
      funk: -> funked = true

    Serenade.view('test', 'li[id="foo" event:click=funk]')
    Serenade.controller('test', TestCon)

    @render '''
      ul
        - view "test"
    '''
    @fireEvent @body.querySelector('li#foo'), 'click'

    expect(funked).to.be.ok

  it 'inits controller with model', ->
    funked = null
    model = { quox: { test: 'foo' } }
    class TestCon
      constructor: (model) -> funked = model.test

    Serenade.view('test', 'li[id="foo" event:click=funk]')
    Serenade.controller('test', TestCon)

    @render '''
      ul
        - in "quox"
          - view "test"
    ''', model
    expect(funked).to.eql('foo')

  it 'inits controller with parent', ->
    funked = null
    parent = { foo: "foo" }
    class TestCon
      constructor: (model, parent) -> funked = parent.foo

    Serenade.view('test', 'li')
    Serenade.controller('test', TestCon)

    @render '''
      ul
        - view "test"
    ''', {}, parent
    expect(funked).to.eql('foo')

  it 'falls back to same controller if none is set up', ->
    funked = false
    class TestCon
      funk: -> funked = true

    Serenade.view('test', 'li[id="foo" event:click=funk]')

    @render '''
      ul
        - view "test"
    ''', {}, new TestCon()
    @fireEvent @body.querySelector('li#foo'), 'click'

    expect(funked).to.be.ok

  it 'calls loaded callback if controller is new', ->
    funked = null
    class TestCon
      loaded: -> funked = 'foo'

    Serenade.view('test', 'li[id="foo"]')
    Serenade.controller('test', TestCon)

    @render '''
      ul
        - view "test"
    '''
    expect(funked).to.eql('foo')

  it 'does not call loaded callback if controller is inherited', ->
    funked = 0
    class TestCon
      loaded: -> funked += 1

    Serenade.view('test', 'li[id="foo"]')

    @render '''
      ul
        - view "test"
    ''', {}, TestCon
    expect(funked).to.eql(1)
