module EYCli
  module Command
    class CreateEnv < Base
      def initialize
        @accounts     = EYCli::Controller::Accounts.new
        @apps         = EYCli::Controller::Apps.new
        @environments = EYCli::Controller::Environments.new
      end

      def invoke
        account = @accounts.fetch_account(options[:account]) if options[:account]
        app = @apps.fetch_app(account, {:app_name => options[:app]})
        @environments.create(app, options_parser.fill_create_env_options(options))
      end

      def help
        <<-EOF

It takes the information from the current directory. It will guide you if it cannot reach all that information.
Usage: ey_cli create_env

Options:
       --app name                 Name of the app to create the environment for.
       --name name                Name of the environment.
       --framework_env env        Type of the environment (production, staging...).
       --url url                  Domain name for the app. It accepts comma-separated values.
       --app_instances number     Number of application instances.
       --db_instances number      Number of database slaves.
       --solo                     A single instance for application and database.
       --stack                    App server stack, either passenger, unicorn or trinidad.
EOF
      end

      def options_parser
        EnvParser.new
      end


      class EnvParser
        require 'slop'

        def parse(args)
          opts = Slop.parse(args, {:multiple_switches => false}) do
            on :app, true
            on :name, true
            on :framework_env, true
            on :url, true
            on :app_instances, true, :as => :integer
            on :db_instances, true, :as => :integer
            #on :util_instances, true, :as => :integer # FIXME: utils instances are handled differently
            on :solo, false, :default => false
            on :stack, true, :matches => /passenger|unicorn|trinidad/
          end
          opts.to_hash
        end

        def fill_create_env_options(options)
          opts = {:name => options[:name], :framework_env => options[:framework_env]}
          if options[:stack]
            case options[:stack].to_sym
            when :passenger then options[:stack] = 'nginx_passenger3'
            when :unicorn   then options[:stack] = 'nginx_unicorn'
            when :trinidad  then options[:ruby_version] = 'JRuby'
            end
          end

          if options[:app_instances] || options[:db_instances] || options[:solo]
            cluster_conf = options.dup
            if options[:solo]
              EYCli.term.say('~> creating solo environment, ignoring instance numbers')
              cluster_conf[:configuration] = 'single'
            else
              cluster_conf[:configuration]    = 'custom'
            end

            opts[:cluster_configuration] = cluster_conf
          end

          opts
        end
      end
    end
  end
end
