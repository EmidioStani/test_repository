#encoding:UTF-8
#!/usr/bin/env ruby
require 'OctoKit'
require 'CSV'
require 'highline/import'



# because github didn't display my random colors
ISSUE_COLORS = ['d4c5f9','e11d21','eb6420','fbca04','009800','006b75','207de5',
				'0052cc','5319e7','f7c6c7','fad8c7','fef2c0','bfe5bf','bfdadc',
				'c7def8', 'bfd4f2']

def get_input(prompt="Enter >",show = true)
	ask(prompt) {|q| q.echo = show}
end

issues_csv = ARGV.shift or raise "Enter Filepath to CSV as ARG1"

user = get_input('Enter Username >')
password = get_input('Enter Password >', '*')

client = Octokit::Client.new \
	:login => user,
	:password => password

user = client.user
user.login

repo = get_input('Enter repo (owner/repo_name) >')

Issue = Struct.new(:title, :body, :labels, :assignee)
issues = Array.new

CSV.foreach issues_csv, headers: true, :row_sep => "\r\n", :col_sep => ";" do |row|
	labels = []
	labels << row['Labels'].split(',') unless row['Labels'].nil?
	issues << Issue.new(row['Title'], row['Description'], labels, row['Assignee'])
end

unique_labels = issues.map{ |i| i.labels }.flatten.map{|j| j.to_s.strip}.uniq
puts "adding labels: #{unique_labels.to_s}"
unique_labels.each do |l|
	begin
		#client.add_label(repo, l, ISSUE_COLORS.sample)
	rescue Octokit::UnprocessableEntity => e
		puts "Unable to add #{l} as a label. Reason: #{e.errors.first[:code]}"
	end
end

#start_time = Time.now

issues.each_with_index do |issue, i|
	puts "creating issue '#{issue.title}'"
	issue_number = client.create_issue(repo, issue.title, issue.body, {:labels => issue.labels.join(','), :assignee => issue.assignee}).number
    #elapsed_seconds = ((Time.now - start_time) * 1000).to_i
    #puts "'#{i}' - elapsed seconds: '#{elapsed_seconds}'"
    if (i+1) % 20 == 0
      sleep(30)
    end
end
