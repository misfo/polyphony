#include "polyphony.h"

VALUE mPolyphony;

ID ID_await_no_raise;
ID ID_call;
ID ID_caller;
ID ID_clear;
ID ID_each;
ID ID_inspect;
ID ID_new;
ID ID_raise;
ID ID_ivar_running;
ID ID_ivar_thread;
ID ID_runnable;
ID ID_runnable_value;
ID ID_size;
ID ID_signal;
ID ID_switch_fiber;
ID ID_transfer;
ID ID_R;
ID ID_W;
ID ID_RW;

VALUE Polyphony_snooze(VALUE self) {
  VALUE ret;
  VALUE fiber = rb_fiber_current();

  Fiber_make_runnable(fiber, Qnil);
  ret = Thread_switch_fiber(rb_thread_current());
  TEST_RESUME_EXCEPTION(ret);
  RB_GC_GUARD(ret);
  return ret;
}

static VALUE Polyphony_suspend(VALUE self) {
  VALUE ret = Thread_switch_fiber(rb_thread_current());

  TEST_RESUME_EXCEPTION(ret);
  RB_GC_GUARD(ret);
  return ret;
}

VALUE Polyphony_trace(VALUE self, VALUE enabled) {
  __tracing_enabled__ = RTEST(enabled) ? 1 : 0;
  return Qnil;
}

void Init_Polyphony() {
  mPolyphony = rb_define_module("Polyphony");

  rb_define_singleton_method(mPolyphony, "trace", Polyphony_trace, 1);

  rb_define_global_function("snooze", Polyphony_snooze, 0);
  rb_define_global_function("suspend", Polyphony_suspend, 0);

  ID_await_no_raise = rb_intern("await_no_raise");
  ID_call           = rb_intern("call");
  ID_caller         = rb_intern("caller");
  ID_clear          = rb_intern("clear");
  ID_each           = rb_intern("each");
  ID_inspect        = rb_intern("inspect");
  ID_ivar_running   = rb_intern("@running");
  ID_ivar_thread    = rb_intern("@thread");
  ID_new            = rb_intern("new");
  ID_raise          = rb_intern("raise");
  ID_runnable       = rb_intern("runnable");
  ID_runnable_value = rb_intern("runnable_value");
  ID_signal         = rb_intern("signal");
  ID_size           = rb_intern("size");
  ID_switch_fiber   = rb_intern("switch_fiber");
  ID_transfer       = rb_intern("transfer");
}