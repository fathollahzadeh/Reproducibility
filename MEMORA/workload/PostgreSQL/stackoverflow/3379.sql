WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 1000
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        MAX(ph.CreationDate) AS ClosureDate,
        (SELECT COUNT(*) FROM PostHistory ph2 WHERE ph2.PostId = p.Id AND ph2.PostHistoryTypeId = 10) AS CloseCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY p.Id, p.Title
),
ReputationBreakdown AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE 
            WHEN b.Class = 1 THEN 3
            WHEN b.Class = 2 THEN 2
            WHEN b.Class = 3 THEN 1
            ELSE 0 
        END) AS BadgePoints
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    ps.CommentCount,
    ps.VoteCount,
    cp.Title AS ClosedPostTitle,
    cp.ClosureDate,
    rb.BadgePoints,
    CASE 
        WHEN ps.VoteCount > 10 THEN 'Highly Voted'
        WHEN ps.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Low Voted'
    END AS VoteCategory,
    CASE 
        WHEN rb.BadgePoints > 5 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM TopUsers tu
JOIN PostSummary ps ON tu.UserId = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.ClosedPostId
JOIN ReputationBreakdown rb ON tu.UserId = rb.UserId
WHERE 
    ps.CommentCount > 3 AND
    (cp.CloseCount IS NULL OR cp.CloseCount < 3)
ORDER BY tu.Reputation DESC, ps.VoteCount DESC;