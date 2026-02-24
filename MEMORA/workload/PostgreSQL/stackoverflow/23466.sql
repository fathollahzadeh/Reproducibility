
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyEarned,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(ph.CreationDate, p.CreationDate) AS LastActiveDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)  
)
SELECT 
    u.DisplayName AS User,
    u.Reputation,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.LastActiveDate,
    (u.TotalBountyEarned - u.TotalDownvotes) AS EffectiveBounty,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.UserId AND b.Class = 1) THEN 'Gold'
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = u.UserId AND b.Class = 2) THEN 'Silver'
        ELSE 'Bronze or No Badge'
    END AS BadgeClass,
    CASE 
        WHEN ps.RankByViews <= 5 THEN 'Top 5 Posts'
        WHEN ps.RankByViews IS NULL THEN 'No Views'
        ELSE 'Regular Post'
    END AS PostRank
FROM UserReputation u
JOIN PostStats ps ON u.UserId = ps.PostId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
AND ps.ViewCount > 100
ORDER BY u.Reputation DESC, ps.ViewCount DESC
LIMIT 50;
