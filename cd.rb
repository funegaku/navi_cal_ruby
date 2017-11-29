# Michio FUJII, fune-gaku.com

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



#Calculation for corse and distance between point and point
class Co_Dist

	#set position
	def set(lat_dep, long_dep, lat_arr, long_arr)
		@lat1 = lat_dep
		long1 = long_dep
		lat2 = lat_arr
		long2 = long_arr

		@dmp = Nav_cal.mp(lat2) - Nav_cal.mp(@lat1)
		@dlat = lat2 - @lat1
		@dlong = Nav_cal.dlong(long1, long2)
		@rad_co = Math.atan2(@dlong*60, @dmp)
	end

	def course

		co = Nav_cal.to_deg (@rad_co)
		if co < 0.0 then
			co = co + 360.0
		end

		return co
	end

	def distance

		if (@dmp).abs <= 0.0001
			dist = @dlong / Math.cos( Nav_cal.to_rad(@lat1) ) * 60.0
		else
			dist = @dlat / Math.cos( @rad_co ) * 60.0
		end

		return dist
	end

end