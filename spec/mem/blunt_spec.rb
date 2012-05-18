require 'spec_helper'

describe "A Very blunt test to make sure that we aren't doing stupid leaks" do
  before do
    #allocate a single context to make sure that v8 loads its snapshot and
    #we pay the overhead.
    V8::Context.new
    @start_memory = process_memory
    GC.stress = true
  end

  after do
    GC.stress = false
  end
  it "won't increase process memory by more than 50% no matter how many contexts we create" do
    if Object.const_defined?(:RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
      pending 'need to figure out how to do memory sanity checks on rbx'
    end
    500.times do
       V8::Context.new
       run_v8_gc
    end
    process_memory.should <= @start_memory * 1.5
  end

  def process_memory
    /\w*[ ]*#{Process.pid}[ ]*([.,\d]*)[ ]*([.,\d]*)[ ]*([\d]*)[ ]*([\d]*)/.match(`ps aux`)[4].to_i
  end

end
