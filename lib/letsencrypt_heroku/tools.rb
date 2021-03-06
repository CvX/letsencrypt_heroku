module LetsencryptHeroku
  module Tools
    def banner(msg, values = nil)
      puts "\n #{Rainbow(msg).blue} #{values.to_s}\n\n"
    end

    def output(name, &block)
      log name
      @_spinner = build_spinner(name)
      @_spinner.auto_spin
      block.call
      @_spinner.success
    rescue LetsencryptHeroku::TaskError
      exit false
    end

    def log(message, level: :info)
      message.to_s.empty? and return
      level == :info ? logger.info(message) : logger.error(message)
    end

    def error(reason = nil)
      log reason, level: :error
      @_spinner && @_spinner.error("(#{reason.strip})")
      raise LetsencryptHeroku::TaskError, reason
    end

    def execute(command, &block)
      log command
      Open3.popen3("unset RUBYOPT; #{command}") do |stdin, stdout, stderr, wait_thr|
        if block
          block.call(stdin, stdout, stderr, wait_thr)
        else
          out, err = stdout.read, stderr.read
          log out
          log err
          wait_thr.value.success? or error(err.force_encoding('utf-8').sub(' ▸    ', 'heroku: '))
        end
      end
    end

    private

    def logger
      @logger ||= begin
        Dir.mkdir('log') unless File.directory?('log')
        Logger.new(File.open('log/letsencrypt_heroku.log', File::WRONLY | File::APPEND | File::CREAT))
      end
    end

    def build_spinner(name)
      TTY::Spinner.new(" :spinner #{name}",
        format:       :dots,
        interval:     20,
        frames:       [ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" ].map { |s| Rainbow(s).yellow.bright },
        success_mark: Rainbow('✔').green,
        error_mark:   Rainbow('✘').red
      )
    end
  end
end
