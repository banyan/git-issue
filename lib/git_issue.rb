#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$KCODE="UTF8"

require 'pp'
require 'rubygems'
require 'uri'
require 'open-uri'
require "net/http"
require "uri"
require 'fileutils'
require 'json'
require 'optparse'
require 'tempfile'
require 'active_support'

module GitIssue
  class Command
    attr_reader :name, :short_name, :description
    def initialize(name, short_name, description)
      @name, @short_name, @description = name, short_name, description
    end
  end

  module Helper


    COMMAND = [:show, :list, :mine, :commit, :update, :branch, :help]
    COMMAND_ALIAS = { :s => :show, :l => :list, :m=> :mine, :c => :commit, :u => :update, :b => :branch, :h => :help}

    USAGE = <<-END
        show    show given issue summary. if given no id, geuss id from current branch name.
        list    listing issues.
        mine    display issues that assigned to you.
        commit  commit with filling issue subject to messsage.if given no id, geuss id from current branch name.
        update  update issue properties. if given no id, geuss id from current branch name.
        branch  checout to branch using specified issue id. if branch dose'nt exisits, create it. (ex ticket/id/<issue_id>)
        help    show usage
    END

    CONFIGURE_MESSAGE = <<-END
    please set issue tracker %s.

      %s
    END

    def configure_error(attr_name, example)
      raise CONFIGURE_MESSAGE % [attr_name, example]
    end


    def configured_value(name)
      res = `git config issue.#{name}`
      res.strip
    end

    def its_klass_of(its_type)
      case its_type
        when /redmine/i then GitIssue::Redmine
        when /github/i  then GitIssue::Github
        else
          raise "unknown issue tracker type : #{its_type}"
      end
    end

    module_function :configured_value, :configure_error, :its_klass_of
  end

  def self.main(argv)
    status = true

    begin
      its_type = Helper.configured_value('type')
      apikey   = Helper.configured_value('apikey')

      Helper.configure_error('type (redmine | github)', "git config issue.type redmine") if its_type.blank?
      Helper.configure_error('apikey', "git config issue.apikey some_api_key")           if apikey.blank?

      its_klass = Helper.its_klass_of(its_type)
      status = its_klass.new(ARGV).execute || true
    rescue => e
      puts e
      puts e.backtrace.join("\n")
      status = false
    end

    exit(status)
  end

end

require File.dirname(__FILE__) + '/git_issue/base'
require File.dirname(__FILE__) + '/git_issue/redmine'
require File.dirname(__FILE__) + '/git_issue/github'