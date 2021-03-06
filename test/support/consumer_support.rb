# Copyright 2012 Red Hat, Inc.
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require './lib/runcible/resources/consumer'
require './lib/runcible/extensions/consumer'

class ConsumerSupport
  def initialize
    @consumer_resource  = TestRuncible.server.resources.consumer
  end

  def self.consumer_id
    'integration_test_consumer_support'
  end

  def create_consumer(package_profile = false)
    destroy_consumer
    consumer = @consumer_resource.create(self.class.consumer_id)
    if package_profile
      @consumer_resource.upload_profile(self.class.consumer_id, 'rpm',
                                        [{'name' => 'elephant', 'version' => '0.2', 'release' => '0.7',
                                          'epoch' => 0, 'arch' => 'noarch', 'vendor' => 'Fedora'}])
    end
    return consumer
  rescue => e
    raise e
  end

  def destroy_consumer
    @consumer_resource.delete(self.class.consumer_id)
  rescue => e
    raise e unless e.class == RestClient::ResourceNotFound
  end
end
