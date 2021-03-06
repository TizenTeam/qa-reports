#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
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

require 'external_service_helper'

module MeegoTestReport

  def MeegoTestReport.format_txt(txt)
    html = []
    ul = false
    txt.gsub! '&', '&amp;'
    txt.gsub! '<', '&lt;'
    txt.gsub! '>', '&gt;'

    txt.each_line do |line|
      line.strip!
      if ul and not line =~ /^\*/
        html << "</ul>"
        ul = false
      elsif line == ''
        html << "<br/>"
      end
      if line == ''
        next
      end

      # Convert markup to HTML
      # Both bold and italic
      line.gsub! /'''''(.+?)'''''/, "<b><i>\\1</i></b>"
      # Bold
      line.gsub! /'''(.+?)'''/, "<b>\\1</b>"
      # Italic
      line.gsub! /''(.+?)''/, "<i>\\1</i>"

      # Links to external services
      SERVICES.each do |s|
        link = Regexp.escape(s['link_uri'])
        link.gsub! /http[s]?/, "http[s]?"
        link.gsub! /%s/, "(\\d+)" # URIs contain a %s for the ID
        line.gsub! /#{link}/ do
          "<a class=\"ext_service fetch ext_service_append\" data-id=\"#{s['prefix']}##{$1}\" href=\"#{s['link_uri'] % $1}\">#{$1}</a>"
        end
      end

      # Any other link
      line.gsub! /\[\[(http[s]?:\/\/.+?) (.+?)\]\]/, "<a href=\"\\1\">\\2</a>"

      # External service IDs [[1234]] or [[BZ#1234]]
      line.gsub! /(\[\[([A-Z]{1,}\#{1})?(\d+)\]\])/ do
        "<a class=\"ext_service fetch ext_service_append\" data-id=\"#{$2}#{$3}\" href=\"#{ExternalServiceHelper.get_external_url($1)}\">#{$3}</a>"
      end

      # Headings, lists, and the rest
      if line =~ /^====\s*(.+)\s*====$/
        html << "<h5>#{$1}</h5>"
      elsif line =~ /^===\s*(.+)\s*===$/
        html << "<h4>#{$1}</h4>"
      elsif line =~ /^==\s*(.+)\s*==$/
        html << "<h3>#{$1}</h3>"
      elsif line =~ /^\*(.+)$/
        if not ul
          html << "<ul>"
          ul = true
        end
        html << "<li>#{$1}</li>"
      else
        html << "#{line}<br/>"
      end
    end

    (html.join '').chomp('<br/>').html_safe
  end

end

module ReportSummary

  def total_cases
    @total_cases ||= meego_test_cases.size
  end

  def total_passed
    @total_passed ||= count_results(MeegoTestCase::PASS)
  end

  def total_failed
    @total_failed ||= count_results(MeegoTestCase::FAIL)
  end

  def total_na
    @total_na ||= count_results(MeegoTestCase::NA) + count_results(MeegoTestCase::CUSTOM)
  end

  def total_measured
    @total_measured ||= count_results(MeegoTestCase::MEASURED)
  end

  def total_cases=(num)
    @total_cases = num
  end

  def total_passed=(num)
    @total_passed = num
  end

  def total_failed=(num)
    @total_failed = num
  end

  def total_na=(num)
    @total_na = num
  end

  def total_measured=(num)
    @total_measured = num
  end

  def total_executed
    total_passed + total_failed
  end

  def run_rate
    safe_div (total_passed + total_failed + total_measured).to_f, total_cases
  end

  def pass_rate
    safe_div total_passed.to_f, (total_cases - total_measured)
  end

  def pass_rate_executed
    safe_div total_passed.to_f, (total_cases - total_measured - total_na)
  end

  def nft_index
    # Select measurements which affect to nft_index and map those calculated indices into an array
    indices = MeegoMeasurement.where(:meego_test_case_id => meego_test_cases).select{|m| m.index.present?}.map &:index

    return 0 if indices.count == 0
    indices.inject(:+) / indices.count
  end

  def metric_change_direction(metric_name)
    return 0 if not prev_summary

    send(metric_name) <=> prev_summary.send(metric_name)
  end

  def change_from_previous(field_name)
    return 0 if not prev_summary

    send(field_name) - prev_summary.send(field_name)
  end

  def total_nft
    # We cannot just add together total_serial_nft and total_non_serial_nft
    # because single test case can contain both and the result would then
    # be incorrect
    @total_nft ||= MeegoMeasurement.select('DISTINCT meego_test_case_id')
        .where(:meego_test_case_id => meego_test_cases)
        .map(&:meego_test_case_id)
      .concat(SerialMeasurementGroup.select('DISTINCT meego_test_case_id')
        .where(:meego_test_case_id => meego_test_cases)
        .map(&:meego_test_case_id))
      .uniq.count
  end

  def total_non_nft
    @total_non_nft ||= total_cases - total_nft
  end

  def total_non_serial_nft
    @total_non_serial_nft ||=
      MeegoMeasurement.select('DISTINCT meego_test_case_id').
        where(:meego_test_case_id => meego_test_cases).count
  end

  def total_serial_nft
    @total_serial_nft ||=
      SerialMeasurementGroup.select('DISTINCT meego_test_case_id').
        where(:meego_test_case_id => meego_test_cases).count
  end

  def has_cases?
    total_cases > 0
  end

  def has_nft?
    total_nft > 0
  end

  def has_non_nft?
    total_non_nft > 0
  end

  def has_non_serial_nft?
    total_non_serial_nft > 0
  end

  def has_serial_nft?
    total_serial_nft > 0
  end

  def calculate_grading
    return 0 if total_cases - total_measured == 0
    case pass_rate
    when 0.9..1.0 then 3
    when 0.4..0.9 then 2
    else 1
    end
  end

  private

  def count_results(result)
    if new_record? || meego_test_cases.loaded?
      meego_test_cases.to_a.count {|x| x.result == result}
    else
      meego_test_cases.count(:conditions => {:result => result})
    end
  end

  def safe_div(dividend, divisor, div_by_zero=0)
    divisor == 0 ? div_by_zero : ( dividend / divisor )
  end

end
