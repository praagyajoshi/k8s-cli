require 'yaml'

class Configuration
  attr_reader :pods, :contexts

  def initialize
    config = YAML.load_file(File.join(__dir__, '../config/application.yml'))
    @pods = config['pods']
    @contexts = config['contexts']
  end
end