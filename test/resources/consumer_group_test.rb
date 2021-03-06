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
require 'minitest/autorun'
require './lib/runcible/resources/consumer_group'
require './lib/runcible/resources/consumer'
require './lib/runcible/extensions/consumer'
require './test/support/repository_support'
require './test/support/consumer_support'

module Resources
  module TestConsumerGroupBase
    def setup
      @resource = TestRuncible.server.resources.consumer_group
      @consumer_group_id = 'integration_test_consumer_group'
    end

    def create_consumer_group
      @resource.create(@consumer_group_id, :display_name => 'foo',
                                           :description => 'Test description.', :consumer_ids => [])
    rescue => e
      puts "Could not create consumer group #{@consumer_group_id}. Exception \n #{e}"
    end

    def destroy_consumer_group
      @resource.delete(@consumer_group_id)
    rescue => e
      puts "Could not destroy consumer group #{@consumer_group_id}. Exception \n #{e}"
    end
  end

  class TestConsumerGroupCreate < MiniTest::Unit::TestCase
    include TestConsumerGroupBase

    def teardown
      destroy_consumer_group
      super
    end

    def test_create
      response = create_consumer_group

      assert_equal @consumer_group_id, response['id']
    end
  end

  class TestConsumerGroupDestroy < MiniTest::Unit::TestCase
    include TestConsumerGroupBase

    def setup
      super
      create_consumer_group
    end

    def test_destroy
      response = @resource.delete(@consumer_group_id)

      assert_equal 200, response.code
    end
  end

  class ConsumerGroupTests  < MiniTest::Unit::TestCase
    include TestConsumerGroupBase

    def setup
      super
      @support = ConsumerSupport.new
      create_consumer_group
    end

    def teardown
      destroy_consumer_group
      super
    end
  end

  class TestConsumerGroup < ConsumerGroupTests
    def test_path
      path = @resource.path

      assert_match 'consumer_groups/', path
    end

    def test_path_with_id
      path = @resource.path(@consumer_group_id)

      assert_match "consumer_groups/#{@consumer_group_id}/", path
    end

    def test_retrieve
      response = @resource.retrieve(@consumer_group_id)

      assert_equal 200, response.code
      refute_empty response
      assert_equal @consumer_group_id, response['id']
      assert_empty response['consumer_ids']
    end
  end

  class ConsumerGroupWithConsumerTests < ConsumerGroupTests
    def setup
      super
      @support = ConsumerSupport.new
      @support.create_consumer
      @criteria = {:criteria =>
                     {:filters =>
                       {:id =>
                          {'$in' => [ConsumerSupport.consumer_id]}
                       }
                     }
                  }
    end

    def teardown
      @support.destroy_consumer
      super
    end
  end

  class TestConsumerGroupAssociate < ConsumerGroupWithConsumerTests
    def test_associate
      response = @resource.associate(@consumer_group_id, @criteria)

      assert_equal 200, response.code
      assert_includes response, ConsumerSupport.consumer_id
    end
  end

  class TestConsumerGroupUnassociate < ConsumerGroupWithConsumerTests
    def setup
      super
      @resource.associate(@consumer_group_id, @criteria)
    end

    def test_unassociate
      assert_includes @resource.retrieve(@consumer_group_id)['consumer_ids'], ConsumerSupport.consumer_id

      response = @resource.unassociate(@consumer_group_id, @criteria)

      assert_equal 200, response.code
      refute_includes response, ConsumerSupport.consumer_id
      refute_includes @resource.retrieve(@consumer_group_id)['consumer_ids'], ConsumerSupport.consumer_id
    end
  end

  class TestConsumerGroupRequiresRepo < ConsumerGroupTests
    def self.before_suite
      RepositorySupport.new.create_and_sync_repo(:importer_and_distributor => true)
    end

    def self.after_suite
      RepositorySupport.new.destroy_repo
    end

    def setup
      super
      @support.create_consumer
      criteria = {:criteria =>
                     {:filters =>
                       {:id => {'$in' => [ConsumerSupport.consumer_id]}}}}

      distro_id = RepositorySupport.new.distributor['id']
      TestRuncible.server.resources.consumer.bind(ConsumerSupport.consumer_id, RepositorySupport.repo_id, distro_id)

      @resource.associate(@consumer_group_id, criteria)
    end

    def teardown
      @support.destroy_consumer
      super
    end

    def test_install_units
      response  = @resource.install_units(@consumer_group_id, ['unit_key' => {:name => 'zsh'}, 'type_id' => 'rpm'])

      assert_equal 202, response.code
      assert response['spawned_tasks'].first['task_id']
    end

    def test_update_units
      response  = @resource.update_units(@consumer_group_id, ['unit_key' => {:name => 'zsh'}, 'type_id' => 'rpm'])

      assert_equal 202, response.code
      assert response['spawned_tasks'].first['task_id']
    end

    def test_uninstall_units
      response  = @resource.uninstall_units(@consumer_group_id, ['unit_key' => {:name => 'zsh'}, 'type_id' => 'rpm'])

      assert_equal 202, response.code
      assert response['spawned_tasks'].first['task_id']
    end
  end
end
