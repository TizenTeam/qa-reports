#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#          Jarno Keskikangas <jarno.keskikangas@leonidasoy.fi>
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

require 'open-uri'
require 'drag_n_drop_uploaded_file'
require 'file_storage'
require 'report_comparison'
require 'cache_helper'

module AjaxMixin
  def remove_attachment
    @preview_id   = params[:id].to_i
    @test_session = MeegoTestSession.find(@preview_id)
    files         = FileStorage.new()
    files.remove_file(@test_session, params[:name])
    render :json => {:ok => '1'}
  end

  def update_title
    @preview_id   = params[:id].to_i
    @test_session = MeegoTestSession.find(@preview_id)

    field         = params[:meego_test_session]
    field         = field.keys()[0]
    @test_session.update_attribute(field, params[:meego_test_session][field])
    @test_session.updated_by(current_user)
    expire_caches_for(@test_session)
    expire_index_for(@test_session)

    render :text => "OK"
  end

  def update_case_comment
    case_id  = params[:id]
    comment  = params[:comment]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:comment, comment)

    test_session = testcase.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

  def update_case_result
    case_id  = params[:id]
    result   = params[:result]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:result, result.to_i)

    test_session = testcase.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session, true)

    render :text => "OK"
  end

  def update_txt
    @preview_id   = params[:id]
    @test_session = MeegoTestSession.find(@preview_id)

    field         = params[:meego_test_session]
    field         = field.keys()[0]
    @test_session.update_attribute(field, params[:meego_test_session][field])
    @test_session.updated_by(current_user)
    expire_caches_for(@test_session)

    sym = field.sub("_txt", "_html").to_sym

    render :text => @test_session.send(sym)
  end


  def update_tested_at
    logger.info("called update_tested_at with #{params.inspect}")
    @preview_id = params[:id]

    if @preview_id
      @test_session = MeegoTestSession.find(@preview_id)

      field         = params[:meego_test_session].keys.first
      logger.warn("Updating #{field} with #{params[:meego_test_session][field]}")
      @test_session.update_attribute(field, params[:meego_test_session][field])
      @test_session.updated_by(current_user)

      expire_caches_for(@test_session)
      expire_index_for(@test_session)

      render :text => @test_session.tested_at.strftime('%d %B %Y')
    else
      logger.warn "WARNING: report id #{@preview_id} not found"
    end
  end

  def update_feature_comment
    set_id = params[:id]
    comments = params[:comment]
    testset = MeegoTestSet.find(set_id)
    testset.update_attribute(:comments, comments)

    test_session = testset.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

  def update_feature_grading
    set_id = params[:id]
    grading = params[:grading]
    testset = MeegoTestSet.find(set_id)
    testset.update_attribute(:grading, grading)
 
    test_session = testset.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

end

class ReportsController < ApplicationController
  include AjaxMixin
  include CacheHelper
  
  before_filter :authenticate_user!, :except => ["view", "print", "compare", "fetch_bugzilla_data"]

  #caches_page :print
  #caches_page :index, :upload_form, :email, :filtered_list
  #caches_page :view, :if => proc {|c|!c.just_published?}
  caches_action :fetch_bugzilla_data,
                :cache_path => Proc.new { |controller| controller.params },
                :expires_in => 1.hour

  def preview
    @preview_id = session[:preview_id] || params[:id]
    @editing    = true
    @wizard     = true

    if @preview_id
      @test_session   = MeegoTestSession.find(@preview_id)
      @report         = @test_session
      @no_upload_link = true

      render :layout => "report"
    else
      redirect_to :action => :upload_form
    end
  end

  def publish
    report_id    = params[:report_id]
    test_session = MeegoTestSession.find(report_id)
    test_session.update_attribute(:published, true)

    expire_caches_for(test_session, true)
    expire_index_for(test_session)

    redirect_to :action          => 'view',
                :id              => report_id,
                :release_version => test_session.release_version,
                :target          => test_session.target,
                :testtype        => test_session.testtype,
                :hwproduct       => test_session.hwproduct
  end

  def view
    if @report_id = params[:id].try(:to_i)
      preview_id = session[:preview_id]

      if preview_id == @report_id
        session[:preview_id] = nil
        @published           = true
      else
        @published = false
      end

      @test_session = MeegoTestSession.find(@report_id)

      return render_404 unless @selected_release_version == @test_session.release_version

      @target    = @test_session.target
      @testtype  = @test_session.testtype
      @hwproduct = @test_session.hwproduct

      @report    = @test_session
      @files = FileStorage.new().list_files(@test_session) or []
      @editing = false
      @wizard  = false

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def print
    if @report_id = params[:id].try(:to_i)
      @test_session = MeegoTestSession.find(@report_id)

      @report       = @test_session
      @editing      = false
      @files = FileStorage.new().list_files(@test_session) or []
      @wizard = false
      @email  = true

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def edit
    @editing = true
    @wizard  = false

    if id = params[:id].try(:to_i)
      @test_session   = MeegoTestSession.find(id)
      @report         = @test_session
      @no_upload_link = true
      @files = FileStorage.new().list_files(@test_session) or []

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def compare
    @comparison = ReportComparison.new()
    @release_version = params[:release_version]
    @target = params[:target]
    @testtype = params[:testtype]
    @comparison_testtype = params[:comparetype]    

    MeegoTestSession.published_hwversion_by_release_version_target_test_type(@release_version, @target, @testtype).each{|hardware|
        left = MeegoTestSession.by_release_version_target_test_type_product(@release_version, @target, @testtype, hardware.hwproduct).first
        right = MeegoTestSession.by_release_version_target_test_type_product(@release_version, @target, @comparison_testtype, hardware.hwproduct).first
        @comparison.add_pair(hardware.hwproduct, left, right)
    }
    @groups = @comparison.groups
    render :layout => "report"
  end


  def fetch_bugzilla_data
    ids       = params[:bugids]
    searchUrl = "http://bugs.meego.com/buglist.cgi?bugidtype=include&columnlist=short_desc%2Cbug_status%2Cresolution&query_format=advanced&ctype=csv&bug_id=" + ids.join(',')
    data      = open(searchUrl)
    render :text => data.read(), :content_type => "text/csv"
  end

  def delete
    id           = params[:id]

    test_session = MeegoTestSession.find(id)

    expire_caches_for(test_session, true)
    expire_index_for(test_session)

    test_session.destroy

    redirect_to :controller => :index, :action => :index
  end

  protected

  def just_published?
    @published
  end
end
