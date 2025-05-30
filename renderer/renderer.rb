# frozen_string_literal: true

require 'erb'
require 'cgi'
require_relative '../helpers/heatmap_helper'

module Renderer
  # Context for ERB rendering: holds locals and includes helper methods.
  class Context
    include HeatmapHelper

    # @param locals [Hash] variables to expose in templates
    def initialize(locals)
      locals.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.__send__(:attr_reader, key)
      end
    end

    # Binding for ERB
    def get_binding
      binding
    end
  end

  # Renders a single ERB template (no layout).
  # @param name [Symbol] template name
  # @param locals [Hash]
  # @return [String]
  def self.render_template(name, locals = {})
    template_path = File.join(__dir__, '../views', "#{name}.erb")
    ERB.new(File.read(template_path), trim_mode: '-').result(Context.new(locals).get_binding)
  end
end
