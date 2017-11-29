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

	# GC distance calculation
	def gc_dist (lat_dep, long_dep, lat_arr, long_arr)

		dlong = dlong(long_dep, long_arr)
		a = Math.sin( to_rad(lat_dep) ) * Math.sin( to_rad(lat_arr) )
		b = Math.cos( to_rad(lat_dep) ) * Math.cos( to_rad(lat_arr) ) * Math.cos( to_rad( dlong ) )

		dist = to_deg( Math.acos( a + b ) ) * 60

		return dist

	end

	module_function :to_rad, :to_deg, :mp, :dlong, :gc_dist

end


class GC_route

	def set(lat_dep, long_dep, lat_arr, long_arr)

		#出発針路・到着針路計算
		p1 = Nav_cal.to_rad( (lat_dep - lat_arr) / 2 )
		p2 = Nav_cal.to_rad( (lat_dep + lat_arr) / 2 )
		dlong_gc = Nav_cal.dlong(long_dep, long_arr)
		long_diff_gc =  Nav_cal.to_rad( dlong_gc /2 )

		x = Nav_cal.to_deg( Math.atan( Math.cos(p1) / ( Math.tan(long_diff_gc) * Math.sin(p2) ) ) )
		y = Nav_cal.to_deg( Math.atan( Math.sin(p1) / ( Math.tan(long_diff_gc) * Math.cos(p2) ) ) )

		if (lat_dep + lat_arr) < 0
			y = y + 180
		end

		if dlong_gc.abs <= 0.0001
			if lat_dep > lat_arr
				@co_dep = @co_arr = 180.0
			elsif lat_dep < lat_arr
				@co_dep = @co_arr = 0.0
			end
		elsif (180.0 - dlong_gc.abs) <= 0.0001
			if lat_dep+lat_arr >= 0.0
				@co_dep = 0.0
				@co_arr = 180.0
			elsif  lat_dep+lat_arr < 0.0
				@co_dep = 180.0
				@co_arr = 0.0
			end
		elsif lat_dep.abs <= 0.00001 && lat_dep == lat_arr
			if dlong_gc > 0.0
				@co_dep = 90.0
				@co_arr = 90.0
			elsif dlong_gc < 0.0
				@co_dep = 270.0
				@co_arr = 270.0
			end
		else
			@co_dep = x + y

			if @co_dep < 0
				@co_dep = @co_dep + 360
			elsif @co_dep > 360
				@co_dep = @co_dep - 360
			end

			@co_arr = 180 - (x - y)

			if @co_arr < 0
				@co_arr = @co_arr + 360
			elsif @co_arr > 360
				@co_arr = @co_arr - 360
			end
		end

		#大圏距離計算
		@dist_gc = Nav_cal.gc_dist(lat_dep, long_dep, lat_arr, long_arr)

		#頂点位置計算
		dLv = Nav_cal.to_deg( Math.atan( 1 / Math.sin( Nav_cal.to_rad(lat_dep) ) / Math.tan( Nav_cal.to_rad(@co_dep) ) ) )

		if Math.sin( Nav_cal.to_rad(lat_dep) ) * Math.cos( Nav_cal.to_rad(@co_dep) ) < 0
			dLv = dLv + 180.0
		elsif dLv > 180.0
			dLv = dLv - 360.0
		end

		@long_v = long_dep + dLv

		if @long_v > 180.0 then
			@long_v = @long_v - 360.0 
		elsif @long_v < -180.0
			@long_v = 360.0 + @long_v
		end
		
		@lat_v = Nav_cal.to_deg( Math.asin( Math.cos( Nav_cal.to_rad(@co_dep) ) / Math.sin( Nav_cal.to_rad(dLv) ) ) ) 

		if Math.sin( Nav_cal.to_rad(dLv) ) < 0
			@lat_v = @lat_v * -1
		end

		if dlong_gc.abs < 0.00001
			if lat_dep > lat_arr
				@lat_v = -90.0
			elsif lat_dep < lat_arr
				@lat_v = 90.0
			end
		elsif 180.0 - dlong_gc.abs < 0.00001
			if lat_dep + lat_arr >= 0
				@lat_v = 90.0
			elsif lat_dep + lat_arr < 0
				@lat_v = -90.0
			end
		elsif lat_dep == lat_arr
			@lat_v = -999 #頂点は存在しない
		end

		#変針点の計算
		interval = 10 #変針点のインターバルを入力　経度差（度）
		@list_wp = Array.new()

		if dlong_gc >= 0
			wp_num = (long_dep / interval).ceil
		elsif dlong_gc < 0
			wp_num = (long_dep / interval).floor
		end

		@list_wp << [lat_dep, long_dep] #出発地点の登録

		loop{

			long_wp = wp_num*interval

			if long_wp <= -180.0
				long_wp = 360.0 + long_wp
			elsif long_wp > 180.0
				long_wp = long_wp - 360.0
			end

			lat_wp = Nav_cal.to_deg( Math.atan( Math.cos( Nav_cal.to_rad( Nav_cal.dlong(long_wp, @long_v ) ) ) * Math.tan( Nav_cal.to_rad(@lat_v) ) ) )

			if dlong_gc >= 0
				if Nav_cal.dlong(long_wp, long_arr) < 0
					break
				end
				wp_num += 1
			elsif dlong_gc < 0
				if Nav_cal.dlong(long_wp, long_arr) > 0
					break
				end
				wp_num -= 1
			end

			@list_wp << [lat_wp, long_wp]  #通過地点の登録

		}

		@list_wp << [lat_arr, long_arr]  #到着地点の登録

	end

	def dep_co
		return @co_dep
	end

	def arr_co
		return @co_arr
	end

	def dist
		return @dist_gc
	end

	def v_position
		return @lat_v, @long_v
	end

	def wp
		return @list_wp
	end

	def wp_co_dist #変針点間の針路と方位を配列で計算　[co, total_dist]
		i = 0
		wp = Array.new
		dist_wp_total = 0.0
		co_wp = 0.0
		d = Co_Dist.new()
		
		while i < @list_wp.length
			if i > 0
				d.set(@list_wp[i-1][0], @list_wp[i-1][1], @list_wp[i][0], @list_wp[i][1])
				co_wp = d.course
				dist_wp_total += d.distance
				
				wp << [co_wp, dist_wp_total]
			end

			i += 1
		end

		return wp
	end

end