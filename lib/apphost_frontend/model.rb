require 'data_mapper'
require 'digest/sha1'
require 'pp'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, (ENV["DATABASE_URL"]|| 'sqlite://'+File.expand_path('../git.db',__FILE__)))
DataMapper::Model.raise_on_save_failure=true

class User
  include DataMapper::Resource

  property :id, Serial
  property :email, Text
  property :password, Text
  property :token, Text

  has n,:keys
  has n,:acl_entries

  def name
    self.email.gsub("@","_at_").gsub(".","__")
  end

  def hasKey
    self.keys.length>0
  end
end

class Key
  include DataMapper::Resource

  property :id, Serial
  property :data, Text

  belongs_to :user

  def name
    user.name+"_"+self.id.to_s
  end
  
  def file
    self.user.name+"_"+self.id.to_s
  end
end


# repo/acls are needed, because it may be possible that
# a user has still repos but no ssh-keys
class AclEntry
  include DataMapper::Resource

  property :id, Serial
  belongs_to :user
  belongs_to :repository
  property :right,String
end

class Repository
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :description, String

  has n,:acl_entries

  def self.createDefault(ops)
    name=ops[:name]
    description=ops[:description]
    user=ops[:user]
    repo=Repository.new({:name=>name,:description=>description})
    repo.save
    acl=AclEntry.new({:user=>user,:repository=>repo,:right=>"RW+"})
    acl.save
    repo
  end
end
DataMapper.finalize
DataMapper.auto_upgrade!
pp Dir.pwd
