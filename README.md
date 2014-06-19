# Chef Databag Manager

A simple command line tool to download, upload and commit encrypted databags to SVN. 
I designed this for me to use for frequent Databag updates and thought maybe it could help others out there save some cycles. 
This is intended to run on a Linux system, but that doesn't mean it won't work on Windows.
I just have not tested it on Windows.

This is the first release. So, I'm sure there is room for improvement and may have a bug or two.

## Prerequisites

1. Ruby 1.9.3+
2. RubyGems
3. Bundler (Optional)

## Setup

1. Extract to a system with knife setup.
2. Install Prerequisite Rubygems
  1. bundle install
3. Configure Settings JSON or YAML (Whichever you prefer)

## Usage

At this point it's fairly simple. If you have the databag_manager_settings.json updated with your configurations; just run the ruby script.

```ruby ./databag_manager.rb```

If you'd like to use YAML instead of JSON; either change the default variable in the Ruby script or run the script using the filepath argument.

```ruby ./databag_manager.rb -f ./databag_manager_settings.yml```

Options:
    -f, --filepath FILEPATH          JSON or YAML Configuration File Full Path if not in same Directory
    -h, --help                       Show this message


## Disclaimer

Use at your own risk. I'm not responsible for any damage or data lose.