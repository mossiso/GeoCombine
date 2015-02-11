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
  # look in geoblacklight env for solr url (maybe in solr_config.yml) Env.fetch
  task :index, [:solr_url] do |t, args|
    begin
      args.with_defaults(solr_url: 'http://127.0.0.1:8983/solr')
      solr = RSolr.connect :url => args[:solr_url]
      xml_files = Dir.glob("tmp/**/*geoblacklight.xml")
      xml_files.each_with_index do |file, i|
        doc = File.read(file)
        begin
          solr.update data: doc
        rescue RSolr::Error::Http => error
          puts error
        end
        # attach to rake's verbose flag? or log
        if i % 1000 == 0
          solr.commit
          puts "Commit to Solr (1000)."
          solr.optimize
        end
      end
    rescue Exception => e
      puts "Error: #{e}"
    end
  end
end
