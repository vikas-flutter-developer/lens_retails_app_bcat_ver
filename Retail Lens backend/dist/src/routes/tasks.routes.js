"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tasksRouter = void 0;
const express_1 = require("express");
const tasks_controller_1 = require("../controllers/tasks.controller");
exports.tasksRouter = (0, express_1.Router)();
exports.tasksRouter.get('/', tasks_controller_1.TasksController.getTasks);
exports.tasksRouter.post('/', tasks_controller_1.TasksController.createTask);
exports.tasksRouter.patch('/:id', tasks_controller_1.TasksController.updateTaskStatus);
exports.tasksRouter.put('/:id', tasks_controller_1.TasksController.updateTask);
exports.tasksRouter.delete('/:id', tasks_controller_1.TasksController.deleteTask);
//# sourceMappingURL=tasks.routes.js.map