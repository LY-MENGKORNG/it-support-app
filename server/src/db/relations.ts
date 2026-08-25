import { defineRelations } from "drizzle-orm";
import { user } from "./schema/user";
import { category } from "./schema/category";
import { comment } from "./schema/comment";
import { requestHistory } from "./schema/request-history";
import { request } from "./schema/request";

export const schema = { category, comment, requestHistory, request, user };
export const relations = defineRelations(schema, (r) => ({
  category: {
    requests: r.many.request({
      from: r.category.id,
      to: r.request.categoryId,
    }),
  },

  comment: {
    request: r.one.request({
      from: r.comment.requestId,
      to: r.request.id,
    }),

    user: r.one.user({
      from: r.comment.userId,
      to: r.user.id,
    }),
  },

  requestHistory: {
    request: r.one.request({
      from: r.requestHistory.requestId,
      to: r.request.id,
    }),

    user: r.one.user({
      from: r.requestHistory.userId,
      to: r.user.id,
    }),
  },

  request: {
    requester: r.one.user({
      from: r.request.requesterId,
      to: r.user.id,

      alias: "request_requester",
    }),

    assignee: r.one.user({
      from: r.request.assigneeId,
      to: r.user.id,

      alias: "request_assignee",
    }),

    category: r.one.category({
      from: r.request.categoryId,
      to: r.category.id,
    }),

    comments: r.many.comment({
      from: r.request.id,
      to: r.comment.requestId,
    }),

    history: r.many.requestHistory({
      from: r.request.id,
      to: r.requestHistory.requestId,
    }),
  },

  user: {
    requestedRequests: r.many.request({
      from: r.user.id,
      to: r.request.requesterId,
    }),

    assignedRequests: r.many.request({
      from: r.user.id,
      to: r.request.assigneeId,
    }),

    comments: r.many.comment({
      from: r.user.id,
      to: r.comment.userId,
    }),

    history: r.many.requestHistory({
      from: r.user.id,
      to: r.requestHistory.userId,
    }),
  },
}))
