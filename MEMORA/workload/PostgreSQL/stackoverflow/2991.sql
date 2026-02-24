
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY p.Id, p.Title, p.CreationDate
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalUpVotes,
        ue.TotalDownVotes,
        ue.TotalComments,
        ue.TotalPosts,
        RANK() OVER (ORDER BY ue.TotalUpVotes DESC) AS UserRank
    FROM UserEngagement ue
)
SELECT 
    te.DisplayName,
    ps.Title,
    ps.CreationDate,
    te.TotalUpVotes,
    te.TotalDownVotes,
    te.TotalComments,
    te.TotalPosts,
    ps.CommentCount,
    ps.AverageBounty,
    CASE 
        WHEN te.TotalUpVotes > te.TotalDownVotes THEN 'Positive Engagement'
        WHEN te.TotalUpVotes < te.TotalDownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM TopEngagedUsers te
JOIN PostStats ps ON te.UserId = ps.PostId
WHERE te.TotalPosts > 0
ORDER BY te.UserRank, te.TotalUpVotes DESC, ps.CommentCount DESC;
