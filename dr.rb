module Nav_cal

	#deg to radian
	def to_rad(data)
		rad = data * Math::PI/180.0
		return rad
	end

	#radian to deg
	def to_deg(data)
		deg = data * 180.0/Math::PI
		return deg
	end

	# mp calculation
	def mp(lat)
		a = Math.tan( to_rad(45.0 + lat*0.5) )
		b = Math.sin( to_rad(lat) )
		mp = 7915.7045 * Math.log10(a) - 22.9448 * b - 0.051 * (b**3)

		return mp
	end

	# dlong calculation
	def dlong(long_dep, long_arr)
		
		dlong = long_arr - long_dep

		if dlong < -180.0
			dlong = 360.0 + dlong
		elsif dlong > 180.0
			dlong = dlong - 360.0
		end
		
		return dlong
	end

	module_function :to_rad, :to_deg, :mp, :dlong

end


class DR_position

	def set(lat_start, long_start, co, dist)
		@lat3 = lat_start
		@long3 = long_start
		@co = co
		@dist = dist
		dlat = @dist * Math.cos( Nav_cal.to_rad(@co) ) / 60.0
		@lat4 = @lat3 + dlat
	end

	def lat
		return @lat4
	end

	def long
		dmp = Nav_cal.mp(@lat4) - Nav_cal.mp(@lat3)
		dlong = Math.tan( Nav_cal.to_rad(@co) ) * dmp / 60.0
		@long4 = @long3 + dlong

		if @long4 >= 180.0 then
			@long4 = @long4 - 360.0
		elsif @long4 < -180.0
			@long4 = 360.0 + @long4
		end

		return @long4
	end

end