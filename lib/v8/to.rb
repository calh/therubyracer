
module V8
  module To
    class << self
      def ruby(value)
        case value
        when V8::C::Function  then V8::Function.new(value)
        when V8::C::Array     then V8::Array.new(value)          
        when V8::C::Object    then V8::Object.new(value)
        when V8::C::String    then value.Utf8Value()
        when V8::C::Date      then Time.at(value.NumberValue())
        else
          value
        end
      end

      alias_method :rb, :ruby

      def v8(value)
        case value
        when V8::Object
          value.instance_eval {@native}
        when String, Symbol
          C::String::New(value.to_s)
        when Proc,Method
          template = C::FunctionTemplate::New() do |arguments|
            rbargs = []
            for i in 0..arguments.Length() - 1
              rbargs << To.ruby(arguments[i])
            end
            V8::Function.rubycall(value, *rbargs)
          end
          return template.GetFunction()
        when ::Array
          C::Array::New(value.length).tap do |a|
            value.each_with_index do |item, i|
              a.Set(i, To.v8(item))
            end
          end
        when ::Hash
          C::Object::New().tap do |o|
            value.each do |key, value|
              o.Set(To.v8(key), To.v8(value))
            end
          end
        when ::Time
          C::Date::New(value)
        when nil,Numeric,TrueClass,FalseClass, C::Value
          value
        else
          rubyobject = C::ObjectTemplate::New()
          rubyobject.SetNamedPropertyHandler(
            NamedPropertyGetter,
            NamedPropertySetter,
            nil,
            nil,
            NamedPropertyEnumerator
          )
          obj = nil
          unless C::Context::InContext()
            cxt = C::Context::New()
            cxt.Enter()
            begin
              obj = rubyobject.NewInstance()
              obj.SetHiddenValue(C::String::New("TheRubyRacer::RubyObject"), C::External::Wrap(value))
            ensure
              cxt.Exit()
            end
          else
            obj = rubyobject.NewInstance()
            obj.SetHiddenValue(C::String::New("TheRubyRacer::RubyObject"), C::External::Wrap(value))
          end
          return obj
        end
      end

      def camel_case(str)
        str.to_s.gsub(/_(\w)/) {$1.upcase}
      end
      
      def perl_case(str)
        str.gsub(/([A-Z])([a-z])/) {"_#{$1.downcase}#{$2}"}.downcase
      end
    end
  end
end