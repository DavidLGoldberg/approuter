function map_id(map_root_path, provided_id)
  --[[ this function provides a way to map an identifier provided by a user
       for example the hash generated by hashing their combined username and password
       to an alternate identity.  This can be used where their identifying credentials
       need to change but they, of course, want to keep their data.  
       The identifiers are expected to be hashes and will be sent in HTTP headers
       as a feature all whitespace will be stripped.
  --]]
  id_map_file_path = string.format("%s/%s.map", map_root_path, provided_id)
  id_map_file = io.open(id_map_file_path, "r")
  if id_map_file then
    mapped_id = id_map_file:read("*a")
    mapped_id = string.gsub(mapped_id, "%s", "")
    id_map_file:close()
    return mapped_id
  else
    return provided_id
  end
end

-- the idea is to provide the ability to translate an inbound id to another id if needed
-- we'll want to do this relatively infrequently as it requires file I/O to do so
-- so....
-- check the inbound request for X-ID-MAP
-- if X-ID-MAP exists, use it to set the ID
-- else
--    get the existing ID from UID cookie
--    transform ID to mapping path (<user id map storage root>/ID.map)
--    if file exists
--      load contents of file
--      set session cookie X-ID-MAP value to contents of file
--    else
--      set session cookie X-ID-MAP value to ID
local cookies = ngx.req.get_headers()["Cookie"]
if not cookies then
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local uid = string.match(cookies, "UID=([^;]+);")
local mapped_id = string.match(cookies, "XMAPPEDID=([^;]+);")

if not uid then
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

if not mapped_id then
  mapped_id = map_id(ngx.var.id_map_root, uid)
end

-- send the mapped id to the application as a header
ngx.req.set_header("UID", mapped_id)

-- send the mapping cookie back to the client
-- this is the thing that could be allowed to not go back to the client in a readable
-- manner.  eventually this could be another lookup, or an encryption or some such thing 
-- that would be far more opaque to the client
ngx.header['Set-Cookie'] = string.format("XMAPPEDID=%s; path=/", mapped_id)