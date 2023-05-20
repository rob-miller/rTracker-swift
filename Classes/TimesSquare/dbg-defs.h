#if DEBUGLOG
#define DBGLog(args...) NSLog(@"%s%d: %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
#else
#define DBGLog(...)
#endif
