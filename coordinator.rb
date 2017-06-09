#!/usr/bin/env ruby
#
this_dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(this_dir) unless $LOAD_PATH.include?(this_dir)

require 'grpc'
require 'metrics_services_pb'

WORK_ORDERS = [
  Metrics::VM.new(ems_ref: 'defaced',   miq_id: '1234'),
  Metrics::VM.new(ems_ref: 'coffee',    miq_id: '56789'),
  Metrics::VM.new(ems_ref: 'deadc0d',   miq_id: '56432'),
  Metrics::VM.new(ems_ref: 'dec0de',    miq_id: '897654'),
  Metrics::VM.new(ems_ref: 'deadbeef',  miq_id: '1234'),
  Metrics::VM.new(ems_ref: 'beaded',    miq_id: '5431234')
]

def run_worker(stub)
  p 'Start Work'
  p '----------'
  vm_enumerator = VmEnumerator.new(WORK_ORDERS, 1)
  stub.start_work(vm_enumerator.each_item) { |r| p "received #{r.inspect}" }
end

# VmEnumerator yields through items, and sleeps between each one
class VmEnumerator
  def initialize(items, delay)
    @items = items
    @delay = delay
  end
  def each_item
    return enum_for(:each_item) unless block_given?
    @items.each do |item|
      sleep @delay
      p "next item to send is #{item.inspect}"
      yield item
    end
  end
end

def main
  stub = Metrics::Collector::Stub.new('localhost:50051', :this_channel_is_insecure)
  run_worker(stub)
end

main
