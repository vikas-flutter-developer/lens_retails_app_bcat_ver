"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tasksRouter = void 0;
const express_1 = require("express");
exports.tasksRouter = (0, express_1.Router)();
exports.tasksRouter.get('/', (_req, res) => {
    res.json({
        summary: {
            pending: 0,
            inProgress: 0,
            completed: 0,
        },
        tasks: [],
    });
});
//# sourceMappingURL=tasks.routes.js.map