# skip-ruby

require_relative '../spec_helper'

$LOAD_PATH << File.expand_path('../support/load_path/long_name', __dir__)
$LOAD_PATH.unshift(File.expand_path('../support/load_path/unshift', __dir__))
$: << File.expand_path('../support/load_path/short_name', __dir__)

require 'long_name_works'
require 'unshift_works'
require 'short_name_works'

describe '$LOAD_PATH' do
  it 'can be appended to at compile-time' do
    LoadPath::LongNameWorks.should be_an_instance_of(Class)
  end

  it 'can be prepended to at compile-time' do
    LoadPath::UnshiftWorks.should be_an_instance_of(Class)
  end

  if RUBY_ENGINE == 'natalie'
    it 'does not support conditional modification' do
      -> { $LOAD_PATH << 'foo' }.should raise_error(LoadError, 'Cannot manipulate $LOAD_PATH at runtime')
      -> { $LOAD_PATH.unshift('foo') }.should raise_error(LoadError, 'Cannot manipulate $LOAD_PATH at runtime')
    end
  end
end

describe '$:' do
  it 'can be appended to at compile-time' do
    LoadPath::ShortNameWorks.should be_an_instance_of(Class)
  end

  if RUBY_ENGINE == 'natalie'
    it 'does not support conditional modification' do
      -> { $: << 'foo' }.should raise_error(LoadError, 'Cannot manipulate $: at runtime')
      -> { $:.unshift('foo') }.should raise_error(LoadError, 'Cannot manipulate $: at runtime')
    end
  end
end
