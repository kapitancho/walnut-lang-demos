module demo-task-controller %% demo-task-api:

==> ListTasks %% [~TaskBoard] :: ^[:] => Result<Array<TaskData>, ExternalError> ::
    %.taskBoard=>allTasks->map(^Task => TaskData :: #->as(type{TaskData}));
==> TaskById %% [~TaskBoard] :: ^[~TaskId] => Result<TaskData, ExternalError|UnknownTaskId> ::
    %.taskBoard=>taskWithId(#)->as(type{TaskData});
==> AddTask %% [~TaskBoard] :: ^[~NewTaskData] => Result<TaskAdded, TaskNotAdded> :: {
    result = %.taskBoard->addTask[Task(#.newTaskData)];
    ?whenTypeOf(result) is {
        type{TaskAdded}: result,
        ~: Error(TaskNotAdded[])
    }
};
==> MarkTaskAsDone %% [~TaskBoard] :: ^[~TaskId] => Result<TaskMarkedAsDone, ExternalError|UnknownTaskId> ::
    %.taskBoard=>taskWithId(#)=>markAsDone;
==> UnmarkTaskAsDone %% [~TaskBoard] :: ^[~TaskId] => Result<TaskUnmarkedAsDone, ExternalError|UnknownTaskId> ::
    %.taskBoard=>taskWithId(#)=>unmarkAsDone;
==> RemoveTask %% [~TaskBoard] :: ^[~TaskId] => Result<TaskRemoved, ExternalError|UnknownTaskId> ::
    %.taskBoard=>removeTask(#);

