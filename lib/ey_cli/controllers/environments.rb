module EYCli
  module Controller
    class Environments
      def create(app, options = {})
        framework_env = options[:framework_env] || 'production'
        env_name      = options[:name] || "#{app.name}_#{framework_env}"

        create_options = {
          :app                               => app,
          'environment[name]'                => env_name,
          'environment[framework_env]'       => framework_env,
          'app_deployment[new][domain_name]' => options[:url] || ''
        }
        create_options.merge! fetch_cluster_options(options[:cluster_configuration])
        env = EYCli::Model::Environment.create(create_options)

        if env.errors?
          EYCli.term.print_errors(env.errors, "Environment creation failed:")
        else
          EYCli.term.success('Environment created successfully')
        end
        env
      end

      def deploy(app, options = {})
        if !app.environments? || app.environments.empty?
          EYCli.term.error <<-EOF
You don't have any environment associated to this application.
Try running `ey_cli create_env' to create your first environment.
EOF
        elsif app.environments.size == 1
          env = app.environments.first
        else
          name = EYCli.term.choose_resource(app.environments,
                                            "I don't know which environment deploy on.",
                                            "Please, select and environment")
          env = EYCli::Model::Environment.find_by_name(name, app.environments)
        end

        if env
          deploy = env.deploy(app, options)

          if deploy.errors?
            EYCli.term.print_errors(deploy.errors, "Application deployment failed:")
          else
            EYCli.term.success('Application deployed successfully')
          end
        else
          EYCli.term.say('Nothing deployed')
        end
      end

      def fetch_cluster_options(options)
        return {} unless options
        options = {
          'cluster_configuration[configuration]' => options[:configuration] || 'cluster',
          'cluster_configuration[ip_id]'         => 'new'
        }
        if options[:configuration] == 'custom'
          options['cluster_configuration[app_server_count]'] = options[:app_instances] || 2
          options['cluster_configuration[db_slave_count]']   = options[:db_instances] || 0
        end
        options
      end
    end
  end
end
