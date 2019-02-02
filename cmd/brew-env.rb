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
    when "new"
      path = ARGV.named.shift
      odie "must specify a path" if path.nil?
      path = Pathname.new(path)
      ohai "Creating a Homebrew environment in #{path}..."
      mkdir_p path
      chdir path do
        system "git", "init", "-q"
        system "git", "config", "remote.origin.url", HOMEBREW_REPOSITORY
        system "git", "config", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"
        system "git", "config", "core.autocrlf", "false"
        system "git", "fetch", "origin", "master:refs/remotes/origin/master",
               "--tags", "--force", "--quiet"
        system "git", "reset", "--quiet", "--hard", "origin/master"
        system "ln", "-sf", HOMEBREW_CELLAR
        Dir.chdir "Library" do
          rmdir "Taps"
          system "ln", "-sf", HOMEBREW_REPOSITORY/"Library/Taps"
        end
        ohai "Next steps:"
        puts "- Run `eval $(brew env activate #{path})` to start using your environment"
        puts "- Run `brew link <formula>` to add an installed formula to your environment"
      end
    when "activate"
      path = ARGV.named.shift
      odie "must specify a path" if path.nil?
      path = Pathname.new(path)
      odie "must specify a path" unless path.exist?
      odie "must specify a Homebrew environment" unless (path/"bin/brew").exist?
      realpath = path.realpath
      puts "export PATH=\"#{realpath}/bin:#{realpath}/sbin:$PATH\""
    else
      odie "subcommand must be one of: new remove activate"
    end
  end
end

Homebrew.env
