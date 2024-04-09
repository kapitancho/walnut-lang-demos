module demo-task %% demo-task-repository-config, demo-task-controller, demo-task-http:

TodoTest = :[];
TodoTest->run(^Any => Any) %% [~TaskBoard] :: {
    allTasks = %.taskBoard->allTasks;
    t1 = Task['My first task', ?noError(Date[2024, 5, 15]), 'This is my first task'];
    t2 = Task['My second task', ?noError(Date[2024, 5, 16]), 'This is my second task'];
    t3 = Task['My third task', ?noError(Date[2024, 5, 17]), 'This is my third task'];
    t2=>markAsDone;
    %.taskBoard->addTask[t1];
    %.taskBoard->addTask[t2];
    %.taskBoard->addTask[t3];
    %.taskBoard->removeTask[t3->id];
    [all: allTasks, t1: t1, t2: t2, t3: t3]
};

main = ^Any => String :: TodoTest[]->run->printed;
