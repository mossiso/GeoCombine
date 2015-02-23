require 'find'
require 'net/http'
require 'json'
require 'rsolr'
require 'fileutils'
require 'colorize'

namespace :geocombine do
  desc 'Clone and index all in one go'
  task :all, [:solr_url] => [:clone, :index]

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

  desc "Delete the Solr index"
  task :delete , [:solr_url] do |t, args|
    begin
      args.with_defaults(solr_url: 'http://127.0.0.1:8983/solr')
      solr = RSolr.connect :url => args[:solr_url]
      puts "Deleting the Solr index."
      solr.delete_by_query '*:*'
      solr.optimize
    rescue Exception => e
      puts "\nError: #{e}".blue
    end
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
      solr = RSolr.connect :url => args[:solr_url], :read_timeout => 720
      puts "Finding geoblacklight.xml files."
      xml_files = Dir.glob("tmp/**/*geoblacklight.xml")
      puts "Loading files into solr."
      xml_files.each_with_index do |file, i|
        @the_file = file
        doc = File.read(file)
        begin
          solr.update data: doc
        rescue RSolr::Error::Http => error
          puts "\n#{file}\n#{error}".red
          next
        end
        # attach the following output to rake's verbose flag? or log
        if i % 100 == 0
          print ".".magenta unless i == 0
        end
        if i % 1000 == 0
          puts " #{i} files uploaded.".light_green unless i == 0
        end
      end
    rescue Exception => e
      puts "\n#{@the_file}\nError: #{e}".yellow
      next
    end
    puts "\nIndexing and optimizing Solr."
    solr.commit
    solr.optimize
    puts "\n"
  end
end
