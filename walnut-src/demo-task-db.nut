module demo-task-db %% demo-task-repository, db:

DatabaseQueryResultRow ==> TaskStorageData @ HydrationError|MapItemNotFound :: [
    id: $ => item('id'),
    title: $ => item('title'),
    description: $ => item('description'),
    isDone: {$ => item('is_done')} == 1,
    dueDate: $ => item('due_date'),
    createdAt: $ => item('created_at')
] => asJsonValue => hydrateAs(type{TaskStorageData});

TaskStorageData ==> DatabaseQueryBoundParameters :: [
    id: $.id,
    title: $.title,
    description: $.description,
    isDone: ?whenIsTrue { $.isDone: 1, ~: 0 },
    dueDate: $.dueDate->asString,
    createdAt: $.createdAt->asString
];

==> TaskRetrieveAll  %% [~DatabaseConnector] :: ^Null => Result<Array<TaskStorageData>, ExternalError> :: {
    retriever = ^Null => Result<Array<TaskStorageData>, HydrationError|MapItemNotFound|DatabaseQueryFailure> ::
        {%.databaseConnector=>query[query: 'SELECT * FROM tasks', boundParameters: [:]]}
            =>map(^DatabaseQueryResultRow => Result<TaskStorageData, HydrationError|MapItemNotFound> :: #=>asTaskStorageData);
    result = retriever();
    ?whenTypeOf(result) is {
        type{Array<TaskStorageData>}: result,
        type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
    }
};
==> TaskRetrieveById %% [~DatabaseConnector] :: ^String<36> => Result<TaskStorageData, UnknownTask|ExternalError> :: {
    taskId = #;
    retriever = ^Null => Result<TaskStorageData, DatabaseQueryFailure|HydrationError|MapItemNotFound|IndexOutOfRange> ::
        {%.databaseConnector=>query[query: 'SELECT * FROM tasks WHERE id = :todoTaskId', boundParameters: [taskId]]}
            =>item(0)=>asTaskStorageData;
    result = retriever();
    ?whenTypeOf(result) is {
        type{TaskStorageData}: result,
        type{Error<IndexOutOfRange>}: @UnknownTask[],
        type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
    }
};
==> TaskPersist      %% [~TaskRetrieveById, ~DatabaseConnector] :: ^TaskStorageData => Result<TaskStorageSuccessful, ExternalError> :: {
    task = #;
    existingTask = %.taskRetrieveById(task.id);
    ?whenTypeOf(existingTask) is {
        type{TaskStorageData}: {
            result = %.databaseConnector->execute[
                query: 'UPDATE tasks SET title = :title, description = :description, is_done = :isDone, due_date = :dueDate WHERE id = :id',
                boundParameters: #->asDatabaseQueryBoundParameters
            ];
            ?whenTypeOf(result) is {
                type{Integer<0..>}: TaskStorageSuccessful[],
                type{Error<DatabaseQueryFailure>}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
            }
        },
        type{Error<UnknownTask>}: {
            result = %.databaseConnector->execute[
                query: 'INSERT INTO tasks (id, title, description, is_done, due_date, created_at) VALUES (:id, :title, :description, :isDone, :dueDate, :createdAt)',
                boundParameters: #->asDatabaseQueryBoundParameters
            ];
            ?whenTypeOf(result) is {
                type{Integer<0..>}: TaskStorageSuccessful[],
                type{Error<DatabaseQueryFailure>}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
            }
        },
        type{Error<ExternalError>}: existingTask
    }
};
==> TaskRemoveById   %% [~TaskRetrieveById, ~DatabaseConnector] :: ^String<36> => Result<TaskStorageSuccessful, UnknownTask|ExternalError> :: {
    taskId = #;
    task = ?noError(%.taskRetrieveById(taskId));
    persister = ^Null => Result<Integer<0..>, DatabaseQueryFailure> ::
        %.databaseConnector=>execute[query: 'DELETE FROM tasks WHERE id = :id', boundParameters: [id: taskId]];
    result = persister();
    ?whenTypeOf(result) is {
        type{Integer}: TaskStorageSuccessful[],
        type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
    }
};

/*
DbTodoBoard = :[];
DbTodoBoard->addTask(^TodoTask => Result<TaskAdded, TaskAlreadyExists|ExternalError>) %% DatabaseConnector :: {
    existing = $->taskWithId[#->id];
    ?whenTypeOf(existing) is {
        type{TodoTask}: @TaskAlreadyExists[#->id],
        ~: {
            result = %->execute[
                query: 'INSERT INTO tasks (id, title, description, is_done, due_date, created_at) VALUES (:id, :title, :description, :isDone, :dueDate, :createdAt)',
                boundParameters: #->asDatabaseQueryBoundParameters
            ];
            ?whenTypeOf(result) is {
                type{Integer<0..>}: TaskAdded[task: #],
                type{Error<DatabaseQueryFailure>}: @{result->error->asExternalError}
            }
        }
    }
};
DbTodoBoard->removeTask(^[~TodoTaskId] => Result<TaskRemoved, UnknownTask|ExternalError>) %% DatabaseConnector :: {
    existing = $->taskWithId[#.todoTaskId];
    ?whenTypeOf(existing) is {
        type{TodoTask}: {
            result = %->execute[
                query: 'DELETE FROM tasks WHERE id = ?',
                boundParameters: [#.todoTaskId]
            ];
            ?whenTypeOf(result) is {
                type{Integer<0..>}: TaskRemoved[task: existing],
                type{Error<DatabaseQueryFailure>}: @{result->error->asExternalError}
            }
        },
        ~: @UnknownTask[#.todoTaskId]
    }
};
DbTodoBoard->taskWithId(^[~TodoTaskId] => Result<TodoTask, HydrationError|MapItemNotFound|UnknownTask|ExternalError>) %% DatabaseConnector :: {
    data = %->query[query: 'SELECT * FROM tasks WHERE id = :todoTaskId', boundParameters: #];
    ?whenTypeOf(data) is {
        type{DatabaseQueryResult}: ?whenTypeOf(data) is {
            type[DatabaseQueryResultRow]: data.0 => asTodoTask,
            ~: @UnknownTask(#)
        },
        type{Error<DatabaseQueryFailure>}: @{data->error->asExternalError}
    }
};
DbTodoBoard->allTasks(^Null => Result<Array<TodoTask>, HydrationError|MapItemNotFound|DatabaseQueryFailure>) %% DatabaseConnector :: { %
    => query[query: 'SELECT * FROM tasks', boundParameters: [:]]}
    => map(^DatabaseQueryResultRow => Result<TodoTask, HydrationError|MapItemNotFound> :: # => asTodoTask);

DbTodoBoard ==> TodoBoard :: [
    addTask: ^TodoTask => Result<TaskAdded, TaskAlreadyExists|ExternalError> :: $->addTask(#),
    removeTask: ^[~TodoTaskId] => Result<TaskRemoved, UnknownTask|ExternalError> :: $->removeTask(#),
    taskWithId: ^[~TodoTaskId] => Result<TodoTask, UnknownTask|ExternalError> :: {
        result = $->taskWithId(#);
        ?whenTypeOf(result) is {
            type{Result<TodoTask, UnknownTask|ExternalError>}: result,
            type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
        }
    },
    allTasks: ^Null => Result<Array<TodoTask>, ExternalError> :: {
        result = $->allTasks;
        ?whenTypeOf(result) is {
            type{Array<TodoTask>}: result,
            type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
        }
    }
];

==> TaskUpdatedEventListener %% [~TodoBoard, ~DatabaseConnector] :: ^TaskMarkedAsDone|TaskUnmarkedAsDone => Result<Null, ExternalError> :: {
    task = #->todoTask;
    existing = %.todoBoard.taskWithId[task->id];
    ?whenTypeOf(existing) is {
        type{TodoTask}: {
            result = %.databaseConnector->execute[
                query: 'UPDATE tasks SET is_done = :isDone WHERE id = :id',
                boundParameters: [isDone: ?whenIsTrue { task->isDone: 1, ~: 0 }, id: task->id]
            ];
            ?whenTypeOf(result) is {
                type{Integer<0..>}: null,
                type{Error<DatabaseQueryFailure>}: @{result->error->asExternalError}
            }
        },
        ~: @ExternalError[errorType: 'UnknownTask', originalError: UnknownTask[task->id], errorMessage: 'error']
    }
};
*/