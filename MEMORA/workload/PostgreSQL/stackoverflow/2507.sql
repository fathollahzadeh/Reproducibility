WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(ph.Comment, 'No Comment') AS LastEditComment,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpvotes - ua.TotalDownvotes AS NetVotes,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.LastEditComment
FROM UserActivity ua
FULL OUTER JOIN PostStatistics ps ON ua.UserId = ps.PostId
WHERE (ua.TotalPosts > 0 OR ps.PostId IS NOT NULL) 
  AND (ua.TotalUpvotes - ua.TotalDownvotes) > 10
ORDER BY NetVotes DESC, ua.DisplayName, ps.PostRank
LIMIT 50;