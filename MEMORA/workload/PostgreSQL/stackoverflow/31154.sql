
WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        0 AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.Level < 2
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(v.BountyAmount) AS AverageBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY p.OwnerUserId
),

UserBadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),

FilteredPosts AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(ct.Name, 'Other') AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
    LEFT JOIN CloseReasonTypes ct ON ph.Comment::integer = ct.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year' 
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    us.PostCount,
    us.PositivePosts,
    us.NegativePosts,
    us.AverageBounty,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges,
    COUNT(f.Id) AS RecentPostsWithCloseReasons
FROM Users u
JOIN PostStats us ON u.Id = us.OwnerUserId
JOIN UserBadgeSummary ubs ON u.Id = ubs.UserId
LEFT JOIN FilteredPosts f ON u.Id = f.OwnerUserId
WHERE u.Reputation > 1000
GROUP BY 
    u.DisplayName, 
    u.Reputation, 
    u.CreationDate, 
    us.PostCount, 
    us.PositivePosts, 
    us.NegativePosts, 
    us.AverageBounty, 
    ubs.GoldBadges, 
    ubs.SilverBadges, 
    ubs.BronzeBadges
HAVING COUNT(f.Id) > 5
ORDER BY u.Reputation DESC;
