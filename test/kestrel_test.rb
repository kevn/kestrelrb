require 'rubygems'
require File.dirname(__FILE__) + '/../lib/kestrel.rb'
require 'test/unit'
class ReliableQueueTest < Test::Unit::TestCase
  
  QUEUE_NAME = 'test_queue'
  
  def setup
    @q = Kestrel::Queue.new(QUEUE_NAME, :timeout => 100)
    @q.drop
    @q.on_error do |exception, msg|
      puts "Exception: #{exception.class}: #{exception.message} (Message: #{msg})"
    end
  end

  def teardown
    @q.drop
  end

  def test_empty
    assert_equal nil, @q.get
  end

  def test_enqueue_dequeue
    s = random_string
    @q.enqueue(s)
    assert_equal s, @q.dequeue
  end

  def test_explicit_requeue
    assert_equal nil, @q.get
    s = random_string
    @q.enqueue(s)
    assert_equal s, @q.dequeue # First time
    @q.abort # requeue
    assert_equal s, @q.dequeue # Second time
    assert_equal nil, @q.dequeue
  end

  # FIXME: This test depends on FIFO, even though Kestrel does not guarantee ordering
  def test_subscribe
    
    100.times do
      @q.enqueue(random_string)
    end
    @q.enqueue("LAST MESSAGE")
    
    results = []
    @q.on_error do
      assert_equal 100, results.size
    end
    
    @q.subscribe do |msg|
      raise Kestrel::Queue::Unsubscribe if msg == "LAST MESSAGE"
      results << msg
    end
    
  end

  def test_stats
    stats = @q.stats
    assert stats.is_a?(Hash)
    assert stats['localhost:22133']['bytes_read'].is_a?(Numeric)
  end
  
protected
  def random_string
    "This is a test #{rand(10_000)}"
  end
end
