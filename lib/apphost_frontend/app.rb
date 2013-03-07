require 'gitolite'
require 'sinatra'
require 'digest/sha1'
require 'json'
require File.expand_path('../model.rb',__FILE__)

class Ga
  @@ga_repo=ENV["GITOLITE_ADMIN_HOME"]||"."

  def self.url(repoName)
    "git@"+HOSTNAME+":"+repoName
  end

  def self.repos
    @@ga_repo.config.repos
  end

  def self.repo
    @@ga_repo
  end

  def self.config
    @@ga_repo.config
  end

  def self.removeKey(dbKey)
    self.update
    key=Gitolite::SSHKey.from_string(File.open(File.join(GITOLITE_ADMIN_HOME,"keydir",dbKey.name+".pub")){|f|f.read},dbKey.name)
    if key
      dbKey.user.acl_entries.each{|acl|
	self.updatePermission(acl.repository)
      }

      @@ga_repo.rm_key(key)
      self.apply
      true
    else
      false
    end
  end

  def self.addKey(dbKey)
    self.update

    keys=@@ga_repo.ssh_keys

    name=dbKey.name
    if (not keys[name]) or keys[name].length==0
      puts "KEY NOT EXISTING - add "
      gkey=Gitolite::SSHKey.from_string(dbKey.data,dbKey.name)
      @@ga_repo.add_key(gkey)
      self.apply
    else
      puts "KEY ALREADY exists"
    end

  end

  def self.update
    @@ga_repo.update
  end

  def self.apply
    @@ga_repo.save
    @@ga_repo.apply
  end

  def self.deleteRepo(dbRepo)
    self.update
    repo=self.repos[dbRepo.name]
    if repo
      @@ga_repo.config.rm_repo(repo)
      self.apply
      true
    else
      false
    end
  end

  def self.updatePermission(dbRepo)
    self.update
    repos=self.repos

    repo=repos[dbRepo.name]
    unless repo 
      repo=Gitolite::Config::Repo.new(dbRepo.name)
      Ga.config.add_repo(repo)
    end

    repo.clean_permissions
    repo.add_permission("RW+","","gadmin")
    repo.add_permission("R","","runner")

    dbRepo.acl_entries.each{|acl|
      acl.user.keys.each{|key|
	repo.add_permission(acl.right,"",key.name)
      }
    }
    self.apply
    self.url(dbRepo.name)
  end
end


class GitoliteAdminApp < Sinatra::Base

  enable  :methodoverride

  helpers do
    def json(data)
      content_type :json
      data.to_json
    end
    def checkLogin
      token=params["token"]
      if token
	User.first({:token=>token})
      else
	false	
      end
    end
  end

  get '/' do
    @repos = Ga.repos
    @repos.to_s
  end

  post '/register' do
    User.create!({:email=>params["email"],:password=>params["password"]})
    json true
  end

  post '/login' do
    user=User.first({:email=>params["email"],:password=>params["password"]})
    if user
      user.token=Digest::SHA1.hexdigest 'mysecret'+user.email+"__"+user.password+Time.now.to_s
      user.save
      json user.token
    else
      json false
    end
  end

  get '/key' do
    user=User.first({:token=>params["token"]})
    if user
      json user.keys
    else
      json []
    end
  end

  post '/key' do
    user=User.first({:token=>params["token"]})
    if user
      if params["key"]
	data=params["key"].chomp.gsub("\n","")
	if user.keys.first({:data=>data})
	  json :state=>false, :error=>"already inserted"
	else
	  k=Key.create!({:user=>user,:data=>data})
	  Ga.addKey(k)
	  json :state=>true
	end
      else
	json :state=>false,:error=>"key invalid"
      end
    else
      json :state=>false,:error=>"invalid token"
    end
  end

  delete '/key' do
    key=User.first({:token=>params["token"]}).keys.first({:data=>params["key"].chomp})
    unless key
      key=User.first({:token=>params["token"]}).keys.first({:id=>params["id"]})
    end
    if key

      key.destroy
      Ga.removeKey(key)

      json :state=>true
    else
      json :state=>false
    end
  end

  get '/repo' do
    json Ga.repos
  end

  post '/repo' do
    user=checkLogin 
    if user and user.hasKey
      repoName=params["name"]
      if not repoName=~/[a-z][a-z0-9_]*/
	pp params
	return json :state=>false, :error=> "Invalid reponame '#{repoName}'"
      end

      dbrepo=Repository.createDefault({:name=>repoName,:user=>user,:description=>params["description"]})

      url=Ga.updatePermission(dbrepo)

      json :state=>true,:url=>url
    else
      json :state=>false,:error=>"Invalid token"
    end
  end

  delete '/repo' do
    user=checkLogin
    if user
      repoName=params["name"]
      repo=Repository.first({:name=>repoName})
      acl=AclEntry.first({:repository=>repo,:user=>user})
      if acl and acl.right=="RW+"
	Ga.deleteRepo(repo)
	return json :state=>true
      end
    end
    json :state=>false
  end
end

