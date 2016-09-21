# A Wishbone Controlled PWM (audio) controller

This PWM controller was designed with audio in mind, although it should be
sufficient for many other purposes.  Specifically, it creates a pulse-width
modulated output, where the amount of time the output is 'high' is determined
by the pulse width data given to it.  Further, the 'high' time is spread out in
bit reversed order.  In this fashion, a halfway point will alternate between
high and low, rather than the normal fashion of being high for half the time
and then low.  This approach was chosen to move the PWM artifacts to higher,
inaudible frequencies and hence improve the sound quality.

The interface supports two addresses:

- Addr[0] is the data register.  Writes to this register will set
a 16-bit sample value to be produced by the PWM logic.
Reads will also produce, in the 17th bit, whether the interrupt
is set or not.  (If set, it's time to write a new data value ...)

- Addr[1] is a timer reload value, used to determine how often the PWM logic
needs its next value.  This number should be set to the number of clock cycles
between reload values.  So, for example, an 80 MHz clock can generate a
44.1 kHz audio stream by reading in a new sample every (80e6/44.1e3 = 1814)
samples.  After loading a sample, the device is immediately ready to load a
second.  Once the first sample completes, the second sample will start going
to the output, and an interrupt will be generated indicating that the device
is now ready for the third sample.  (The one sample buffer allows some
flexibility in getting the new sample there fast enough ...)

