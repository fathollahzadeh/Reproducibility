WITH RankedBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS rn
    FROM Badges b
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS UserScoreAdjustment,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AvgPostScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
FinalData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        COALESCE(rb.Name, 'No Badge') AS LatestBadge,
        ur.UserScoreAdjustment,
        ur.AvgPostScore,
        rp.PostId,
        rp.Score AS PostScore,
        rp.CreationDate AS PostCreationDate
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.UserId
    LEFT JOIN RankedBadges rb ON u.Id = rb.UserId AND rb.rn = 1
    LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
)
SELECT 
    fd.UserId,
    fd.DisplayName,
    fd.Reputation + COALESCE(fd.UserScoreAdjustment, 0) AS AdjustedReputation,
    fd.LatestBadge,
    fd.PostId,
    fd.PostScore,
    fd.PostCreationDate,
    CASE 
        WHEN fd.PostScore IS NULL THEN 'No Posts'
        WHEN fd.PostScore >= (SELECT AVG(Score) FROM Posts) THEN 'Above Average Post'
        ELSE 'Below Average Post'
    END AS PostPerformance
FROM FinalData fd
WHERE fd.Reputation > 1000
ORDER BY AdjustedReputation DESC, fd.PostCreationDate DESC
LIMIT 50;