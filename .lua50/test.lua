require "std.base.lua"

function printf (...)
	write (call (format,arg))
end

print('foo %s', 'bar')
printf('foo %s', 'bar')
