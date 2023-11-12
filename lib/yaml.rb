require 'natalie/inline'
require 'yaml.cpp'

__ld_flags__ '-lyaml'

module YAML
  __bind_static_method__ :dump, :YAML_dump
end

class Object
  def to_yaml
    YAML.dump(self)
  end
end
