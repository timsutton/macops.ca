# frozen_string_literal: true

require 'time'
require 'erb'
require 'rubocop/rake_task'

TEMPLATE = <<~TMPL
  ---
  title: <%= title %>
  date: <%= date %>
  slug: <%= slug %>
  tags:
    - fill_these_in
  ---
TMPL

def slugify(str)
  str.downcase.tr(' ', '-')
end

def render_template(metadata, path)
  b = binding
  metadata.each do |k, v|
    b.local_variable_set(k, v)
  end
  tmpl = ERB.new(TEMPLATE).result b
  File.write(path, tmpl)
end

task default: [:build]

desc 'Lint with Rubocop'
RuboCop::RakeTask.new(:lint)

desc 'Build the site'
task :build do
  sh 'hugo'
end

desc 'Compose a new post, and open it in ST3'
task :new, [:title] do |_t, args|
  now = Time.now
  slug = slugify(args[:title])
  post_path = "content/post/#{now.to_date.iso8601}-#{slug}.md"
  raise "New post already exists: #{post_path}" if File.exist?(post_path)

  metadata = {
    title: args[:title],
    date: now.iso8601,
    slug: slug
  }
  render_template(metadata, post_path)

  sh "open -b com.sublimetext.3 #{post_path}"
end
