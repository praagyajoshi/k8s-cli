require 'cli/ui'
require 'open3'

def main
  # Initialise the CLI UI
  CLI::UI::StdoutRouter.enable

  initialise
end

def initialise
  system 'clear'
  welcome_message
  puts
  show_choices
end

def any_key_continues
  puts
  print 'Press any key to continue...'
  STDIN.gets
end

def show_choices
  CLI::UI::Prompt.ask('Please choose an action:') do |handler|
    handler.option('See memory/CPU utilisation') { execute_top }
    handler.option('Connect to a pod') { show_connection_choices }
    handler.option('List HPA') { list_hpa }
    handler.option('List pods') { list_pods }
    handler.option('Change context') { show_context_choices }
    handler.option('Quit') { exit_cli }
  end
end

def exit_cli
  exit
end

def list_hpa
  execute_and_wait('kubectl get hpa', true)
end

def list_pods
  execute_and_wait('kubectl get pods', true)
end

def execute_top
  execute_and_wait('kubectl top pods', true)
end

def execute_and_wait(command, return_to_main = false)
  sg = CLI::UI::SpinGroup.new
  result = ''

  sg.add('Fetching...') do
    result, = Open3.capture3(command)
  end
  sg.wait

  puts
  puts result

  return unless return_to_main

  any_key_continues
  initialise
end

def show_context_choices
  CLI::UI::Prompt.ask('Select new context:') do |handler|
    handler.option('Production') { set_new_context('production') }
    handler.option('Staging') { set_new_context('staging') }
    handler.option('BF/CM') { set_new_context('bfcm') }
  end
end

def set_new_context(type)
  sg = CLI::UI::SpinGroup.new

  sg.add('Setting context...') do |spinner|
    case type
    when 'bfcm'
      command = 'aws eks update-kubeconfig --region us-east-2 --name shopify-stream-bfcm'
    when 'production'
      command = 'aws eks update-kubeconfig --region us-east-1 --name shopify-stream-production'
    when 'staging'
      command = 'aws eks update-kubeconfig --region eu-west-1 --name shopify-stream-staging'
    end

    Open3.capture3(command)
    spinner.update_title('Context set!')
  end
  sg.wait

  any_key_continues
  initialise
end

def show_connection_choices
  CLI::UI::Prompt.ask('Which kind of pod do you want to connect to?') do |handler|
    handler.option('API') { connect_to_pod('stream-api') }
    handler.option('Index') { connect_to_pod('stream-worker-index') }
    handler.option('Enrich') { connect_to_pod('stream-worker-enrich') }
    handler.option('Troubleshooting') { connect_to_pod('troubleshooting') }
  end
end

def connect_to_pod(type = 'stream-api')
  pod_name = find_pod(type)

  if pod_name.empty?
    puts 'Could not find pod!'
    any_key_continues
    initialise
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

  puts
  system "kubectl exec -it #{pod_name} /bin/sh"
end

def find_pod(type = 'stream-api')
  sg = CLI::UI::SpinGroup.new
  result = ''
  pod_name = ''

  sg.add('Looking for pod...') do
    result, = Open3.capture3('kubectl get pods')
  end
  sg.wait

  line_nb = 1
  result.each_line do |line|
    # next if line_nb == 1

    line_nb += 1

    data = line.gsub(/\s+/, ' ').strip.split(' ')
    name = data[0]

    if name.include?(type)
      pod_name = name
      break
    end
  end

  pod_name
end

def welcome_message
  CLI::UI::Frame.open('Welcome to K8S CLI') do
    puts CLI::UI.fmt "{{*}} Context: #{get_context}"
  end
end

def get_context
  result = `kubectl config current-context`
  if result.include?('-bfcm')
    'BF/CM'
  elsif result.include?('-production')
    'Production'
  elsif result.include?('-staging')
    'Staging'
  end
end

# Run the main method
main