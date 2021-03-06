require_relative '../spec_helper'
require_relative '../render_shared'

describe 'Behave rendering' do
  include HelperFactories

  include_context 'shared render'
  it_behaves_like 'a BDD renderer', uid_should_be_in_outline: true do
    let(:language) {'behave'}
    let(:rendered_actionwords) {
      [
        'from behave import *',
        '',
        '# This should be added to environment.py',
        '# from steps.actionwords import Actionwords',
        '#',
        '# def before_scenario(context, scenario):',
        '#     context.actionwords = Actionwords()',
        '',
        'use_step_matcher(\'re\')',
        '',
        '',
        '@when(r\'the following users are available on "(.*)"\')',
        'def impl(context, site, datatable = \'||\'):',
        '    context.actionwords.the_following_users_are_available_on_site(site, context.table)',
        '',
        '',
        '@given(r\'the "(.*)" of "(.*)" is weird "(.*)" "(.*)"\')',
        'def impl(context, order, parameters, p0, p1):',
        '    context.actionwords.the_order_of_parameters_is_weird(p0, p1, parameters, order)',
        '',
        '',
        '@given(r\'I am on the "(.*)" home page\')',
        '@when(r\'I am on the "(.*)" home page\')',
        'def impl(context, site, free_text = \'\'):',
        '    context.actionwords.i_am_on_the_site_home_page(site, context.text)',
        '',
        '',
        '@given(r\'I login on "(.*)" "(.*)"\')',
        'def impl(context, site, username):',
        '    context.actionwords.i_login_on(site, username)',
        '',
        '',
        '@then(r\'you cannot play croquet\')',
        'def impl(context):',
        '    context.actionwords.you_cannot_play_croquet()',
        '',
        '',
        '@given(r\'an untrimed action word\')',
        'def impl(context):',
        '    context.actionwords.an_untrimed_action_word()',
        '',
        '',
        '@then(r\'you obtain "(.*)"\')',
        'def impl(context, color):',
        '    context.actionwords.you_obtain_color(color)',
        '',
        '',
        '@given(r\'the color "(.*)"\')',
        'def impl(context, color):',
        '    context.actionwords.the_color_color(color)',
        '',
        '',
        '@when(r\'you mix colors\')',
        'def impl(context):',
        '    context.actionwords.you_mix_colors()',
        '',
        '',
        ''
      ].join("\n")
    }

    let(:actionword_without_quotes_in_regexp_rendered) {
      [
        "",
        "@given(r'the color (.*)')",
        "def impl(context, color):",
        "    context.actionwords.the_color_color(color)"
      ].join("\n")
    }

    let(:rendered_free_texted_actionword) {[
      'def the_following_users_are_available(self, free_text = \'\'):',
      '    pass',
      ''].join("\n")}

    let(:rendered_datatabled_actionword) {[
      'def the_following_users_are_available(self, datatable = \'\'):',
      '    pass',
      ''].join("\n")}

    let(:rendered_empty_scenario) { "\nScenario: Empty Scenario\n" }
  end

  it 'strips last colon of an actionword name' do
    # If your action word is called "Do something:", Behave will try to match "Do something"
    aw = make_actionword('I do something:')
    project = make_project("Colors",
      scenarios: [
        make_scenario('My scenario',
          body: [
            make_call("I do something:",  annotation: "when")
          ])
      ],
      actionwords: [aw]
    )
    Hiptest::NodeModifiers.add_all(project)

    options =  context_for(only: "step_definitions", language: 'behave')
    expect(aw.render(options)).to eq([
      "",
      "@when(r'I do something')",
      "def impl(context):",
      "    context.actionwords.i_do_something()"
    ].join("\n"))
  end

  it 'escapes single quotes' do
    aw = make_actionword("It's working")
    project = make_project("Colors",
      scenarios: [
        make_scenario('My scenario',
          body: [
            make_call("It's working",  annotation: "when")
          ])
      ],
      actionwords: [aw]
    )
    Hiptest::NodeModifiers::GherkinAdder.add(project)

    options =  context_for(only: "step_definitions", language: 'behave')
    expect(aw.render(options)).to eq([
      "",
      "@when(r'It\\'s working')",
      "def impl(context):",
      "    context.actionwords.its_working()"
    ].join("\n"))
  end

  it 'sorts the steps by RegExp length to avoid AmbiguousSteps' do
    aw = make_actionword('I do "things"', parameters: [
      make_parameter('things')
    ])
    aw1 = make_actionword('I do "things" and "stuff"', parameters: [
      make_parameter('things'),
      make_parameter('stuff')
    ])

    project = make_project("Colors",
      actionwords: [aw, aw1],
      scenarios: [
        make_scenario('My scenario',
          body: [
            make_call('I do "things"',  annotation: "when"),
            make_call('I do "things" and "stuff"',  annotation: "when")
          ])
      ]
    )

    Hiptest::NodeModifiers::ParentAdder.add(project)
    Hiptest::NodeModifiers::GherkinAdder.add(project)

    options = context_for(only: "step_definitions", language: 'behave')

    expect(project.children[:actionwords].render(options)).to eq([
      %|from behave import *|,
      %||,
      %|# This should be added to environment.py|,
      %|# from steps.actionwords import Actionwords|,
      %|#|,
      %|# def before_scenario(context, scenario):|,
      %|#     context.actionwords = Actionwords()|,
      %||,
      %|use_step_matcher('re')|,
      %||,
      %||,
      %|@when(r'I do "(.*)" and "(.*)"')|,
      %|def impl(context, things, stuff):|,
      %|    context.actionwords.i_do_things_and_stuff(things, stuff)|,
      %||,
      %||,
      %|@when(r'I do "(.*)"')|,
      %|def impl(context, things):|,
      %|    context.actionwords.i_do_things(things)|,
      %||
    ].join("\n"))
  end

  it_behaves_like 'a BDD renderer with library actionwords', uid_should_be_in_outline: true do
    let(:language) {'behave'}
    let(:framework) {''}

    let(:rendered_library_actionwords) {
      [
        'from behave import *',
        '',
        '',
        'use_step_matcher(\'re\')',
        '',
        '',
        '@given(r\'My first action word\')',
        'def impl(context):',
        '    context.actionwords.getDefaultLibrary().my_first_action_word()',
        '',
        '',
        '',
        '',
        '',
        ''
      ].join("\n")
    }
  end

  it_behaves_like 'a renderer handling libraries' do
    let(:language) {'behave'}
    let(:framework) {''}

    let(:actionwords_rendered) {
      [
        '# encoding: UTF-8',
        '',
        'from steps.actionword_library import ActionwordLibrary',
        '',
        '',
        'class Actionwords(ActionwordLibrary):',
        '    def __init__(self):',
        '        pass',
        '',
        '    def my_project_action_word(self):',
        '        pass',
        '',
        '    def my_high_level_project_actionword(self):',
        '        self.my_project_action_word()',
        '',
        '    def my_high_level_actionword(self):',
        '        self.getDefaultLibrary().my_first_action_word()',
        ''
      ].join("\n")
    }

    let(:libraries_rendered) {
      [
        '# encoding: UTF-8',
        '',
        'from steps.default_library import DefaultLibrary',
        'from steps.web_library import WebLibrary',
        '',
        '',
        'class ActionwordLibrary:',
        '    def getDefaultLibrary(self):',
        '        return DefaultLibrary(self)',
        '',
        '    def getWebLibrary(self):',
        '        return WebLibrary(self)',
        ''
      ].join("\n")
    }

    let(:first_lib_rendered) {
      [
        '# encoding: UTF-8',
        '',
        'from behave import *',
        '',
        '',
        'class DefaultLibrary:',
        '    __instance = None',
        '',
        '    def __new__(cls, context):',
        '        if DefaultLibrary.__instance is None',
        '            DefaultLibrary.__instance = object.__new__(cls)',
        '',
        '        return DefaultLibrary.__instance',
        '',
        '    def my_first_action_word(self):',
        '        # Tags: priority:high wip',
        '        pass',
        ''
      ].join("\n")
    }

    let(:second_lib_rendered) {
      [
        '# encoding: UTF-8',
        '',
        'from behave import *',
        '',
        '',
        'class WebLibrary:',
        '    __instance = None',
        '',
        '    def __new__(cls, context):',
        '        if WebLibrary.__instance is None',
        '            WebLibrary.__instance = object.__new__(cls)',
        '',
        '        return WebLibrary.__instance',
        '',
        '    def my_second_action_word(self):',
        '        # Tags: priority:low done',
        '        pass',
        ''
      ].join("\n")
    }
  end
end
