
WITH PostScores AS (
    SELECT
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
    GROUP BY p.Id, p.OwnerUserId
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.AccountId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(ps.Upvotes) AS TotalUpvotes,
        SUM(ps.Downvotes) AS TotalDownvotes,
        SUM(ps.CommentCount) AS TotalComments,
        AVG(ps.BadgeCount) AS AverageBadges,
        COUNT(DISTINCT CASE WHEN ps.Rank = 1 THEN ps.PostId END) AS TopPostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN PostScores ps ON p.Id = ps.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.AccountId
),
ClosingReasons AS (
    SELECT
        ph.UserId AS CloserUserId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id 
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.UserId
)
SELECT
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalUpvotes,
    u.TotalDownvotes,
    u.TotalComments,
    u.AverageBadges,
    u.TopPostCount,
    cr.CloseCount,
    COALESCE(cr.CloseReasons, 'No closes') AS CloseReasons
FROM UserStatistics u
LEFT JOIN ClosingReasons cr ON u.UserId = cr.CloserUserId
WHERE u.Reputation > (
    SELECT AVG(Reputation) FROM Users
    WHERE Location IS NOT NULL
) 
ORDER BY u.TotalPosts DESC, u.TotalUpvotes DESC
LIMIT 50;
