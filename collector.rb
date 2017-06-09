#!/usr/bin/env ruby
#
this_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(this_dir) unless $LOAD_PATH.include?(this_dir)

require 'grpc'
require 'metrics_services_pb'

# ServerImpl provides an implementation of the Worker Service
class ServerImpl < Metrics::Collector::Service
  def start_work(work_orders)
    WorkEnumerator.new(work_orders).each_item
  end
end

class WorkEnumerator
  def initialize(work_orders)
    @work_orders  = work_orders
  end

  def each_item
    return enum_for(:each_item) unless block_given?
    begin
      @work_orders.each do |vm|
        puts "Thread #{Thread.current.object_id} : Working with #{vm.inspect}"
        sleep(10)
        yield Metrics::Status.new(current: vm, status: "handled by #{Thread.current.object_id}", error_code: 0)
      end
    rescue StandardError => e
      fail e # signal completion via an error
    end
  end
end

def main
  port = '0.0.0.0:50051'
  s = GRPC::RpcServer.new
  s.add_http2_port(port, :this_port_is_insecure)
  GRPC.logger.info("... running insecurely on #{port}")
  s.handle(ServerImpl.new())
  s.run_till_terminated
end

main
