require "cli_parser"

module Homebrew
  module_function

  def env
    Homebrew::CLI::Parser.parse do
      usage_banner <<~EOS
        `env` [<options>]

        Command for Homebrew environments
      EOS

      switch :verbose
      switch :debug
    end

    case ARGV.named.shift
    when "create"
      path = ARGV.named.shift
      odie "must specify a path" if path.nil?
      path = Pathname.new(path)
      ohai "Creating a Homebrew environment in #{path}..."
      mkdir_p path
      chdir path do
        mkdir_p "bin"
        ln_s HOMEBREW_REPOSITORY/"bin/brew", "bin/brew"
        ln_s HOMEBREW_CELLAR, "Cellar"
        fullpath = Pathname.new(Dir.getwd).realpath
        Pathname.new("bin/brew-activate").write <<~EOS
          #!/bin/sh
          eval $(#{fullpath}/bin/brew shellenv)
        EOS
        chmod "+x", "bin/brew-activate"
        ohai "Next steps:"
        puts <<~EOS
          - Run `eval $(brew env activate #{path})`
            or `source #{path}/bin/brew-activate`
            to start using your environment"
          - Run `brew link <formula>` to add an installed formula to your environment
        EOS
      end
    when "activate"
      path = ARGV.named.shift
      odie "must specify a path" if path.nil?
      path = Pathname.new(path)
      odie "must specify a path" unless path.exist?
      odie "must specify a Homebrew environment" unless (path/"bin/brew").exist?
      exec path/"bin/brew", "shellenv"
    else
      odie "subcommand must be one of: create, activate"
    end
  end
end

Homebrew.env
