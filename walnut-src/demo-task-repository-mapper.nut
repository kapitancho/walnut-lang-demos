module demo-task-repository-mapper %% demo-task-model, demo-task-repository:

TaskStorageData ==> Task @ HydrationError :: $->asJsonValue->hydrateAs(type{Task});

Task ==> TaskStorageData @ HydrationError :: [
    id: $.id,
    title: $.title,
    isDone: $.isDone->value,
    dueDate: $.dueDate->asString,
    createdAt: $.createdAt->asString,
    description: $.description
]->asJsonValue->hydrateAs(type{TaskStorageData});

==> TaskSource %% [~TaskRetrieveAll] :: ^Null => Result<Array<Task>, ExternalError> :: {
    result = %.taskRetrieveAll();
    ?whenTypeOf(result) is {
        type{Array<TaskStorageData>}: {
            result = result->map(^TaskStorageData => Result<Task, HydrationError> :: #->asTask);
            ?whenTypeOf(result) is {
                type{Array<Task>}: result,
                type{Error<HydrationError>}: @ExternalError[errorType: result->type->printed, originalError: #, errorMessage: 'error']
            }
        },
        type{Error<ExternalError>}: result
    }
};

==> SingleTaskSource %% [~TaskRetrieveById] :: ^[~TaskId] => Result<Task, UnknownTaskId|ExternalError> :: {
    result = %.taskRetrieveById(#.taskId);
    ?whenTypeOf(result) is {
        type{TaskStorageData}: {
            result = result->asTask;
            ?whenTypeOf(result) is {
                type{Task}: result,
                type{Error<HydrationError>}: @ExternalError[errorType: result->type->printed, originalError: #, errorMessage: 'error']
            }
        },
        type{Error<UnknownTask>}: @UnknownTaskId(#),
        type{Error<ExternalError>}: result
    }
};

TaskPersistEventListener = ^TaskAdded|TaskMarkedAsDone|TaskUnmarkedAsDone => Result<Null, ExternalError>;
==> TaskPersistEventListener %% [~TaskPersist] :: ^TaskAdded|TaskMarkedAsDone|TaskUnmarkedAsDone => Result<Null, ExternalError> :: {
    data = #->task->asTaskStorageData;
    ?whenTypeOf(data) is {
        type{TaskStorageData}: {
            result = %.taskPersist(data);
            ?whenTypeOf(result) is {
                type{TaskStorageSuccessful}: null,
                type{Error<ExternalError>}: result
            }
        },
        type{HydrationError}: @ExternalError[errorType: data->type->printed, originalError: #, errorMessage: 'error']
    }
};

TaskRemoveEventListener = ^TaskRemoved => Result<Null, ExternalError>;
==> TaskRemoveEventListener %% [~TaskRemoveById] :: ^TaskRemoved => Result<Null, ExternalError> :: {
    result = %.taskRemoveById(#->task->id);
    ?whenTypeOf(result) is {
        type{TaskStorageSuccessful}: null,
        type{Error<ExternalError>}: result
    }
};
