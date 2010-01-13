kestrelrb
=========

Kestrelrb is a Ruby library for [Kestrel](http://github.com/robey/kestrel), the Scala Queue server written by [@robey](http://twitter.com/Robey) at Twitter. Kestrel's interface follows the Memcached API fairly closely and can be accessed with any Memcached client library. This gem uses the memcache-client gem as its interface, but provides queue-specific interface supporting reliable GETs.

Examples:

    @q = Kestrel::Queue.new('test_queue', :timeout => 100)
    @q.enqueue("Message 1")
    @q.dequeue # => "Message 1"
    @q.subscribe do |msg|
      puts "Got a message: #{msg.inspect}"
    end

Project Status
------
This code runs reliably in production.

Known Issues
------------
* If an error occurs within a subscribe loop, Kestrel makes the message *immediately* available to the current or other connected clients. This can cause essentially an infinite loop as the same message is endlessly dequeued, errors and aborts. It is recommended that Queue#abort be called only if the error is conclusively transient in nature, and that non-transient errors cause the message to be submitted to a failure queue with a different processing strategy.

Note on Patches/Pull Requests
-----------------------------
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
   bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2010 Kevin E. Hunt. See LICENSE for details.
