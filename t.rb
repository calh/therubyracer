require 'v8'

puts V8::Context.class

c = V8::Context.new

puts c.eval_js.class.inspect



# 
# puts c.pooh()



