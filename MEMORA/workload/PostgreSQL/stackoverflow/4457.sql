
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.AnswerCount,
        p.CommentCount,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS PopularityRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, ah.AcceptedAnswerId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pm.Title AS PostTitle,
    pm.Score AS PostScore,
    pm.ViewCount AS PostViewCount,
    pm.PopularityRank
FROM UserActivity ua
JOIN PostMetrics pm ON pm.AcceptedAnswerId = ua.UserId
WHERE ua.UserRank <= 10
ORDER BY ua.TotalPosts DESC, pm.PopularityRank;
