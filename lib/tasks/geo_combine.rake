require 'find'
require 'net/http'
require 'json'
require 'rsolr'
require 'fileutils'

namespace :geocombine do
  desc 'Clone all OpenGeoMetadata repositories'
  task :clone do
    FileUtils.mkdir_p('tmp')
    ogm_api_uri = URI('https://api.github.com/orgs/opengeometadata/repos')
    ogm_repos = JSON.parse(Net::HTTP.get(ogm_api_uri)).map{ |repo| repo['git_url']}
    ogm_repos.each do |repo|
      if repo =~ /^git:\/\/github.com\/OpenGeoMetadata\/edu.*/
        system "cd tmp && git clone #{repo}"
      end
    end
  end
  desc 'Delete the tmp directory'
  task :clean do
    puts "Removing 'tmp' directory."
    FileUtils.rm_rf('tmp') 
  end
  desc '"git pull" OpenGeoMetadata repositories'
  task :pull do
    Dir.glob('tmp/*').map{ |dir| system "cd #{dir} && git pull origin master" if dir =~ /.*edu.*./ }
  end
  desc 'Index all of the GeoBlacklight documents'
  task :index do
    solr = RSolr.connect :url => 'http://192.168.59.103:49155/solr'
    Find.find('tmp') do |path|
      if path =~ /.*geoblacklight.xml$/
        doc = File.read(path)
        begin
          solr.update data: doc
          solr.commit
        rescue RSolr::Error::Http => error
          puts error
        end
      end
    end
  end
end
