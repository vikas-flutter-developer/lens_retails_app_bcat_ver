import { TasksService } from './tasks.service';
export declare class TasksController {
    private readonly tasksService;
    constructor(tasksService: TasksService);
    list(): {
        summary: {
            pending: number;
            inProgress: number;
            completed: number;
        };
        tasks: never[];
    };
}
