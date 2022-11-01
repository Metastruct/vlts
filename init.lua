-- awful --

--local lfs = require'lfs'

-- uncomment for debug
--if not pcall(require,'vstruct') and not package.path:find([[;.\?\init.lua]],1,true) then
--	package.path=package.path..[[;.\?\init.lua]]
--end



require'minigcompat'
require'binfuncs'

local function wrap(ok, ...)
	if ok then return ... end
	print""
	print("FAIL", ...)
end

local function SAFE(func, ...)
	return wrap(xpcall(func, debug.traceback, ...))
end

local file, out = ...

if not file or not out then
	print[[Usage: vlts "c:\mymap\map.vmf" "c:\mymap\map_out.vmf"]]
	return
end
out = out or file..'.stripped.vmf'


local function get_removables(dat)
	
	local lua_triggers={}
	
	local lastfindpos=30
	for i=1,10000 do
		local l,r=dat:find('"lua_trigger"',lastfindpos,true)
		if l==nil then
			break
		end
		local L
		for off=l,l-8192,-1 do
			--print(dat:sub(off,off+32))
			if dat:sub(off,off)=='\n' and dat:sub(off,off+16):find("^\nentity[\r\n][\r\n]?%{") then
				L=off
				--print"woo"
				break
			end
		end
		
		assert(not L or L<l,"start of entity after lua_trigger string...")
		
		local R1,R2,str=dat:find("([\r\n]%})[\r\n]",r)
		R=R2 and R1+#str-1
		assert(not R or R>l,"end of entity before lua_trigger string...")
		
		if L and R then
			
			if L>R then
				assert (L<R,"L>R")
			end
			--assert((R-L)<2048,"too long")
			lua_triggers = lua_triggers or {}
			table.insert(lua_triggers,{L,R})
			lastfindpos=R+4
		else
			lastfindpos=r+1
		end
		
	end

	return lua_triggers

end

		function string:split(delimiter)
		  local result = { }
		  local from  = 1
		  local delim_from, delim_to = string.find( self, delimiter, from  )
		  while delim_from do
			table.insert( result, string.sub( self, from , delim_from-1 ) )
			from  = delim_to + 1
			delim_from, delim_to = string.find( self, delimiter, from  )
		  end
		  table.insert( result, string.sub( self, from  ) )
		  return result
		end


local function main()

	local fin = io.open(file,'rb')
	local fout = io.open(out,'wb')
	local dat = fin:read("*all")
	print"Parsing..."
	local removables=get_removables(dat)
	print("Reconstructing...")
	
	local start=0
	for i=1,#removables do
		local l,r = removables[i][1],removables[i][2]
		fout:write(dat:sub(start+1,l-2))
		start=r
	end
	print("Stripped",#removables,"lua_trigger entities")
	fout:write(dat:sub(start+1,-1))
	fin:close()
	fout:close()
end

main()
