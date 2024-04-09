module event:

EventListener = ^Nothing => Result<Null, ExternalError>;
EventBus = $[listeners: Array<EventListener>];
