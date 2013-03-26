#
# This file is part of meego-test-reports
#
# Copyright (C) 2012 Leonidas Ltd.
#
# Authors: Vesa Poikajärvi <vesa.poikajarvi@leonidasoy.fi>
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

class ErrorsController < ApplicationController
  def not_found
    render :file => "#{Rails.root}/public/404.html", :status => :not_found, :layout => false
  end
end
