require 'cli/ui'
require 'open3'
require_relative './commands'
require_relative './configuration'

class KubernetesCli
  class << self
    def start
      # Initialise the CLI UI
      CLI::UI::StdoutRouter.enable
      @configuration = Configuration.new
      render_welcome_screen
    end

    private

    # Render methods
    # --------------

    def render_welcome_screen
      clear_screen
      render_context_banner
      render_options
    end

    def render_context_banner
      CLI::UI::Frame.open('K8S CLI') do
        puts CLI::UI.fmt "{{*}} Context: #{current_context}"
      end
    end

    def render_options
      CLI::UI::Prompt.ask('Please choose an action:') do |handler|
        handler.option('See memory/CPU utilisation') { execute_and_wait(Commands::Kubernetes.utilisation) }
        handler.option('Connect to a pod') { render_pod_choices }
        handler.option('List HPA') { execute_and_wait(Commands::Kubernetes.list_hpa) }
        handler.option('List pods') { execute_and_wait(Commands::Kubernetes.list_pods) }
        handler.option('Change context ') { render_context_choices }
        handler.option('Quit') { quit_cli }
      end
    end

    def render_pod_choices
      CLI::UI::Prompt.ask('Which kind of pod do you want to connect to?') do |handler|
        @configuration.pods.each do |pod|
          handler.option(pod['displayName']) do
            connect_to_pod(pod['type'])
          end
        end
        render_go_back_option handler
      end
    end

    def render_context_choices
      CLI::UI::Prompt.ask('Select new context:') do |handler|
        @configuration.contexts.each do |pod|
          handler.option(pod['displayName']) do
            update_context(pod['displayName'])
          end
        end
        render_go_back_option handler
      end
    end

    def render_go_back_option(handler)
      handler.option('Go back') do
        render_welcome_screen
      end
    end

    # Commands
    # --------

    def clear_screen
      system Commands::System.clear_screen
    end

    def quit_cli
      clear_screen
      exit
    end

    def any_key_continues
      puts
      print 'Press any key to continue...'
      STDIN.gets
    end

    def execute_and_wait(command)
      spinner = CLI::UI::SpinGroup.new
      result = ''

      spinner.add('Fetching...') do
        result, = Open3.capture3(command)
      end
      spinner.wait

      puts
      puts result

      any_key_continues
      render_welcome_screen
    end

    def update_context(type)
      context = @configuration.contexts.find do |con|
        con['displayName'].casecmp(type).zero?
      end
      command = Commands::AWS.update_context(
        context['region'],
        context['name']
      )

      spinner = CLI::UI::SpinGroup.new
      spinner.add('Setting context...') do |spinner|
        # TODO: Handle failure
        Open3.capture3(command)
        spinner.update_title('Context set!')
      end
      spinner.wait

      any_key_continues
      render_welcome_screen
    end

    def connect_to_pod(type)
      pod_name = find_pod(type)

      if pod_name.empty?
        puts 'Oops, could not find that pod!'
        any_key_continues
        render_welcome_screen
      else
        execute_connection(pod_name)
      end
    end

    def execute_connection(pod_name)
      sg = CLI::UI::SpinGroup.new

      sg.add("Connecting to #{pod_name}...") do
        sleep 0.7
      end
      sg.wait

      system Commands::Kubernetes.connect_to_pod(pod_name)
    end

    def find_pod(type)
      spinner = CLI::UI::SpinGroup.new
      result = ''
      pod_name = ''

      spinner.add('Looking for pod...') do
        result, = Open3.capture3(Commands::Kubernetes.list_pod_names)
      end
      spinner.wait

      result.each_line do |line|
        if line.include?(type)
          pod_name = line.strip
          break
        end
      end

      pod_name
    end

    def current_context
      result, status = Open3.capture2(Commands::Kubernetes.current_context)
      return 'Unable to fetch current context' unless status.success?

      # TODO: Fetch from configuration
      if result.include?('stream-testing')
        'Testing'
      elsif result.include?('shopify-stream-production')
        'Production'
      elsif result.include?('shopify-stream-staging')
        'Staging'
      else
        'Unknown context'
      end
    end
  end
end