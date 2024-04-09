module demo-task-api %% demo-task-model:

TaskData = [id: String<36>, title: String<1..>, createdAt: DateAndTime, dueDate: Date, isDone: Boolean, description: String];
NewTaskData = [title: String<1..>, dueDate: Date, description: String];

Task ==> TaskData :: [
    id: $.id, title: $.title, createdAt: $.createdAt, dueDate: $.dueDate, isDone: $.isDone->value, description: $.description
];

TaskNotAdded = :[];

ListTasks = ^[:] => Result<Array<TaskData>, ExternalError>;
TaskById = ^[~TaskId] => Result<TaskData, ExternalError|UnknownTaskId>;
AddTask = ^[~NewTaskData] => Result<TaskAdded, ExternalError|TaskNotAdded>;
MarkTaskAsDone = ^[~TaskId] => Result<TaskMarkedAsDone, ExternalError|UnknownTaskId>;
UnmarkTaskAsDone = ^[~TaskId] => Result<TaskUnmarkedAsDone, ExternalError|UnknownTaskId>;
RemoveTask = ^[~TaskId] => Result<TaskRemoved, ExternalError|UnknownTaskId>;
