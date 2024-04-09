module demo-task-model %% datetime, event:

TaskId = String<36>;
Task = $[id: TaskId, title: String<1..>, isDone: Mutable<Boolean>, dueDate: Date, createdAt: DateAndTime, description: String];

TaskSource = ^Null => Result<Array<Task>, ExternalError>;
UnknownTaskId = $[~TaskId];
SingleTaskSource = ^[~TaskId] => Result<Task, UnknownTaskId|ExternalError>;

TaskBoard = $[~TaskSource, ~SingleTaskSource];

TaskAdded          = $[~Task]; TaskAdded->task(^Null => Task) :: $.task;
TaskMarkedAsDone   = $[~Task]; TaskMarkedAsDone->task(^Null => Task) :: $.task;
TaskUnmarkedAsDone = $[~Task]; TaskUnmarkedAsDone->task(^Null => Task) :: $.task;
TaskRemoved        = $[~Task]; TaskRemoved->task(^Null => Task) :: $.task;

Task[title: String<1..>, dueDate: Date, description: String] %% [~Clock, ~Random] :: [
    id: %.random->uuid,
    title: #.title,
    isDone: Mutable[type{Boolean}, false],
    dueDate: #.dueDate,
    createdAt: %.clock->now,
    description: #.description
];

Task->id(^Null => TaskId) :: $.id;
Task->isDone(^Null => Boolean) :: $.isDone->value;
Task->markAsDone(^Null => Result<TaskMarkedAsDone, ExternalError>) %% [~EventBus] :: {
    $.isDone->SET(true);
    %.eventBus=>fire(TaskMarkedAsDone[$])
};
Task->unmarkAsDone(^Null => Result<TaskUnmarkedAsDone, ExternalError>) %% [~EventBus] :: {
    $.isDone->SET(false);
    %.eventBus=>fire(TaskUnmarkedAsDone[$])
};

TaskAlreadyExists = $[~Task];
TaskBoard->addTask(^[~Task] => Result<TaskAdded, TaskAlreadyExists|ExternalError>) %% [~SingleTaskSource, ~EventBus] :: {
    existingTask = %.singleTaskSource[#.task->id];
    ?whenTypeOf(existingTask) is {
        type{Task}: @TaskAlreadyExists(#),
        type{Error<UnknownTaskId>}: %.eventBus=>fire(TaskAdded(#)),
        type{Error<ExternalError>}: existingTask
    }
};
TaskBoard->removeTask(^[~TaskId] => Result<TaskRemoved, UnknownTaskId|ExternalError>) %% [~SingleTaskSource, ~EventBus] :: {
    existingTask = %.singleTaskSource(#);
    ?whenTypeOf(existingTask) is {
        type{Task}: %.eventBus=>fire(TaskRemoved[existingTask]),
        type{Error<UnknownTaskId|ExternalError>}: existingTask
    }
};
TaskBoard->taskWithId(^[~TaskId] => Result<Task, UnknownTaskId|ExternalError>) %% [~SingleTaskSource] :: %.singleTaskSource(#);
TaskBoard->allTasks(^Null => Result<Array<Task>, ExternalError>) %% [~TaskSource] :: %.taskSource();