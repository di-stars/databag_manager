#!/usr/bin/env ruby

#region Includes

  require 'fileutils'
  require 'json'
  require 'yaml'
  require 'highline/import'
  require 'optparse'
  require 'pp'
  require 'open3'

#endregion Includes


#region Options

  # Defaults
  @options = Hash.new
  @options['filepath'] = 'databag_manager_settings.json'
  # @options[:action][:download] = false
  # @options[:action][:upload] = false
  # @options[:action][:commit] = false

  # Options Parsing
  options_parser = OptionParser.new do |opts|
    opts.banner = "Usage: databag_manager.rb [options]"
    opts.separator ""
    opts.separator "Options:"

    opts.on("-f", "--filepath FILEPATH", "JSON or YAML Configuration File Full Path if not in same Directory") do |opt|
      @options['filepath'] = opt
    end

    # opts.on("-s", "--secretpath SECRETPATH", "Path to Chef Secret File") do |opt|
    #   @options['local_paths']['secretpath'] = opt
    # end

    opts.on_tail("-h", "--help", "Show this message" ) do
      puts opts
      exit
    end

  end
  options_parser.parse(ARGV)

#endregion Options


#region Variables

  # Import Databag List (JSON or YAML)
  if File.exist?(@options['filepath'])
    file_extension = File.extname(@options['filepath'])
    if file_extension == '.json'
      @settings = JSON.parse( IO.read(@options['filepath']) )
    elsif file_extension == '.yaml' || file_extension == '.yml'
      @settings = YAML.load_file(@options['filepath'])
    else
      puts "ERROR: Unknown Rile Type (#{file_extension})"
      raise
    end
  else
    puts 'ERROR: Databag List Not Found!'
    exit 1
    raise
  end

  # Merge Local Paths from JSON to Options Variable
  @options['local_paths'] = @settings['local_paths']

  # Versions
  @script_version  = '1.0.3-20140604'

#endregion Variables


#region Prerequisites

  # Verify Knife Setup
  # if File.exist?(File.expand_path('~/.chef/knife.rb'))
  # else
  # end

  # Check SVN client installed

  # Check Paths?

#endregion Prerequisites


#region Methods

  def show_header
    system 'clear' unless system 'cls'
    puts "Databag Manager v#{@script_version} | Ruby v#{RUBY_VERSION} | by Levon Becker"
    puts '------------------------------------------------------------------'
    # puts "DEBUG: Settings (#{@settings})"
    # puts "DEBUG: Options (#{@options})"
    # puts "DEBUG: Settings Local Paths (#{@settings['local_paths']})"
    # puts "DEBUG: Options Local Paths (#{@options['local_paths']})"
    # puts "DEBUG: File Path (#{@options['filepath']})"
    # puts "DEBUG: Secret Path (#{@options['local_paths']['secretpath']})"
    # puts "DEBUG: Temp Path (#{@options['local_paths']['temppath']})"
    # puts "DEBUG: SVN ROOT (#{@options['local_paths']['svnroot']})"
    # puts "DEBUG: SVN Path (#{@options['svnpath']})"
    # puts "DEBUG: Databag (#{@options['databag']})"
    # puts "DEBUG: Databag Path (#{@options['databag_path']})"
    # puts "DEBUG: Databag Items (#{@options['items']})"
    # puts '------------------------------------------------------------------'
  end

  def show_subheader(subtext)
    puts subtext
    puts '------------------------------------------------------------------'
    puts ''
  end

  def set_values(databag, values)
    @options['databag'] = databag
    @options['svnpath'] = values['svn_path']
    @options['items'] = Hash.new
    @options['items'] = values['items']
    @options['databag_path'] = "#{@options['local_paths']['temppath']}/#{@options['databag']}"
  end

  def run_download
    show_header
    show_subheader('TRIGGERING DOWNLOAD')
    puts 'Please Wait...'
    puts ''

    # Create Temp Folder if Needed
    FileUtils.mkdir_p(@options['databag_path']) unless File.exists?(@options['databag_path'])

    downloaded_items = Array.new
    @options['items'].each do |item|
      command = "knife data bag show #{@options['databag']} #{item} -Fj --secret-file #{@options['local_paths']['secretpath']} > #{@options['databag_path']}/#{item}.json"
      out, err, status = Open3.capture3('bash', stdin_data: command)
      if status.exitstatus != 0
        puts "ERROR (#{item}): #{err}"
        puts "STATUS (#{item}): #{status}"
        exit status.exitstatus
      end
      unless out.nil? || out.empty?
        puts "OUTPUT (#{item}): #{out}"
      end
      downloaded_items << "#{item}.json"
    end

    show_header
    show_subheader('COMPLETED')
    puts 'Download Path'
    puts '------------------'
    puts "#{@options['databag_path']}"
    puts ''
    puts 'Downloaded Files'
    puts '------------------'
    puts downloaded_items
    puts ''
  end

  def run_upload()
    show_header
    show_subheader('TRIGGERING UPLOAD')
    puts 'Please Wait...'
    puts ''

    uploaded_items = Array.new
    @options['items'].each do |item|
      command = "knife data bag from file #{@options['databag']} #{@options['databag_path']}/#{item}.json --secret-file #{@options['local_paths']['secretpath']}"
      out, err, status = Open3.capture3('bash', stdin_data: command)
      if status.exitstatus != 0
        puts "ERROR (#{item}): #{err}"
        puts "STATUS (#{item}): #{status}"
        exit status.exitstatus
      end
      unless out.nil? || out.empty?
        puts "OUTPUT (#{item}): #{out}"
      end
      uploaded_items << "#{item}.json"
    end

    show_header
    show_subheader('COMPLETED')
    puts 'JSON Path'
    puts '------------------'
    puts "#{@options['databag_path']}"
    puts ''
    puts 'Uploaded Files'
    puts '------------------'
    puts uploaded_items
    puts ''
  end

  def run_commit()
    show_header
    show_subheader('TRIGGERING COMMIT')
    puts 'Please Wait...'
    puts ''

    # Update SVN Repos
    show_header
    show_subheader('TRIGGERING COMMIT')
    puts 'Updating SVN'
    puts ''
    puts 'Please Wait...'
    puts ''
    command = "svn up #{@options['local_paths']['svnroot']}/*"
    out, err, status = Open3.capture3('bash', stdin_data: command)
    if status.exitstatus != 0
      puts "ERROR (SVN UPDATE): #{err}"
      puts "STATUS (SVN UPDATE): #{status}"
      exit status.exitstatus
    end
    unless out.nil? || out.empty?
      puts "OUTPUT (SVN UPDATE): #{out}"
    end
    svnupdate_results = out.split("\n")
    sleep(5)

    # Download encrypted json files
    show_header
    show_subheader('TRIGGERING COMMIT')
    puts 'Downloading Encrypted Databags to JSON Files'
    puts ''
    puts 'Please Wait...'
    puts ''
    downloaded_items = Array.new
    @options['items'].each do |item|
      command = "knife data bag show #{@options['databag']} #{item} -Fj > #{@options['svnpath']}/#{item}.json"
      out, err, status = Open3.capture3('bash', stdin_data: command)
      if status.exitstatus != 0
        puts "ERROR (#{item}): #{err}"
        puts "STATUS (#{item}): #{status}"
        exit status.exitstatus
      end
      unless out.nil? || out.empty?
        puts "OUTPUT (#{item}): #{out}"
      end
      downloaded_items << "#{item}.json"
    end
    downloaded_results = [
      'Download Path',
      '------------------',
      "#{@options['svnpath']}",
      '',
      'Downloaded Files',
      '------------------',
      downloaded_items,
      ''
    ]
    puts downloaded_results
    sleep(5)

    # Commit encrypted json files to svn
    show_header
    show_subheader('TRIGGERING COMMIT')
    puts 'Commiting Encrypted JSON Files to SVN'
    puts ''
    puts 'Please Wait...'
    puts ''
    command = "svn commit -m 'Updating data bags' #{@options['svnpath']}"
    out, err, status = Open3.capture3('bash', stdin_data: command)
    if status.exitstatus != 0
      puts "ERROR (SVN COMMIT): #{err}"
      puts "STATUS (SVN COMMIT): #{status}"
      exit status.exitstatus
    end
    unless out.nil? || out.empty?
      puts "OUTPUT (SVN COMMIT): #{out}"
    end
    commit_results = out
    sleep(5)

    show_header
    show_subheader('COMPLETED')
    puts 'SVN Update Results'
    puts '------------------------------------------------------------------'
    puts ''
    puts "SVN Path (#{@options['svnpath']})"
    puts ''
    puts svnupdate_results.last(10)
    puts ''
    puts 'Download Results'
    puts '------------------------------------------------------------------'
    puts ''
    puts downloaded_results
    puts ''
    puts 'Commit Results'
    puts '------------------------------------------------------------------'
    puts ''
    puts commit_results
    puts ''
  end

#endregion Methods


#region Menu: Action Selection

  show_header
  show_subheader('SELECT ACTION')

  begin
    choose do |menu|
      #menu.layout = :menu_only
      #menu.header = 'Action Selection'
      menu.prompt  =  '> '
      menu.choice(:Download) { puts 'Download Selected'; @action = 'download' }
      menu.choice(:Upload) { puts 'Upload Selected'; @action = 'upload' }
      menu.choice(:Commit) { puts 'Commit Selected'; @action = 'commit' }
      menu.choice(:Quit, 'Exit program.') { exit }
    end
  end

#endregion Menu: Action Selection


#region Menu: Select Environment

  show_header
  show_subheader('SELECT DATABAG')

  begin
    choose do |menu|
      #menu.layout = :menu_only
      #menu.header = 'Action Selection'
      menu.prompt  =  '> '
      @settings['databags'].sort_by { |databag| databag }.each do |databag, values|
        menu.choice(databag.downcase) { set_values(databag, values) }
      end
      menu.choice(:Quit, 'Exit program.') { exit }
    end
  end

#endregion Menu: Select Environment


#region Run Action

  if @action == 'download'
    run_download
  elsif @action == 'upload'
    run_upload
  elsif @action == 'commit'
    run_commit
  else
    puts 'ERROR: Unknown Action'
    exit 1
    raise
  end

#endregion Run Action


=begin

  TODO:
  1. run_download: Delete files in directory so don't end up uploading other json files that may be hanging around?
  2. Add download, upload, commit switch
  3. Add enter databag name option (match to json/yaml)
  4. run_upload: Add non secret/encrypted upload option?
  5. Add Dynamic Databag + Databag Item + SVN Path discovery?
  6. Write Prerequisites section logic

=end