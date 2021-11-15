module Commands
  class Kubernetes
    class << self
      def utilisation
        'kubectl top pods'
      end

      def connect_to_pod(pod_name)
        "kubectl exec -it #{pod_name} /bin/sh"
      end

      def list_hpa
        'kubectl get hpa'
      end

      def list_pods
        'kubectl get pods'
      end

      def list_pod_names
        'kubectl get pods --no-headers -o custom-columns=":metadata.name"'
      end

      def current_context
        'kubectl config current-context'
      end
    end
  end

  class AWS
    class << self
      def update_context(region, name)
        "aws eks update-kubeconfig --region #{region} --name #{name} --profile ecommerce"
      end
    end
  end

  class System
    class << self
      def clear_screen
        'clear'
      end
    end
  end
end