
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - u.CreationDate))/86400) AS AverageDaysSinceCreation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.AcceptedAnswerId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.AverageDaysSinceCreation,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.HasAcceptedAnswer
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.TotalPosts > 5
ORDER BY 
    ua.TotalUpvotes DESC, 
    ps.UpvoteCount DESC
LIMIT 100;
