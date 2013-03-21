#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#
require 'spec_helper'
require 'file_storage'
require 'tmpdir'
require 'fileutils.rb'
require 'rspec/rails/mocks.rb'

describe FileStorage do
  before(:each) do
    @temp = Dir.mktmpdir("FileStorage")
    @storage = FileStorage.new(@temp, "files/")
    @session = mock_model(MeegoTestSession, {:id => 1})
  end

  after(:each) do
    FileUtils.remove_dir(@temp)
  end

  it "should return empty array when files are not stored for target" do
    @storage.list_files(@session).should == []
  end

  it "should be able to add file attachements of meego_test_session into storage and list them in creation order" do
    @storage.add_file(@session, File.new('app/assets/images/icon_alert.gif'), 'icon_alert.gif')
    sleep 1.1 # MacOS filesystem has 1sec resolution
    @storage.add_file(@session, File.new('public/images/ajax-loader.gif'), 'f/oo.gif')
    @storage.list_files(@session).should == [
        {:name => "icon_alert.gif", :path => "meego_test_sessions/1/icon_alert.gif", :url => "files/meego_test_sessions/1/icon_alert.gif"},
        {:name => "foo.gif", :path => "meego_test_sessions/1/foo.gif", :url => "files/meego_test_sessions/1/foo.gif"}
    ]
  end

  it "should be able to add file attachements of meego_test_session into storage and remove them" do
    @storage.add_file(@session, File.new('public/images/ajax-loader.gif'), 'bar.gif')
    @storage.list_files(@session).should == [{:name => "bar.gif", :path => "meego_test_sessions/1/bar.gif", :url => "files/meego_test_sessions/1/bar.gif"}]
    @storage.remove_file(@session, 'bar.gif')
    @storage.list_files(@session).should == []
  end
end
