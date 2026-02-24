WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AverageScores AS (
    SELECT
        OwnerUserId,
        AVG(Score) AS AvgScore
    FROM
        Posts
    GROUP BY
        OwnerUserId
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rp.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(ascores.AvgScore, 0) AS AverageScore,
        COALESCE(tb.BadgeCount, 0) AS GoldBadgeCount,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
    LEFT JOIN (
        SELECT
            OwnerUserId,
            COUNT(*) AS RecentPostCount
        FROM RecentPosts
        GROUP BY OwnerUserId
    ) rp ON u.Id = rp.OwnerUserId
    LEFT JOIN AverageScores ascores ON u.Id = ascores.OwnerUserId
    LEFT JOIN TopBadges tb ON u.Id = tb.UserId
)
SELECT 
    us.DisplayName,
    us.RecentPostCount,
    us.AverageScore,
    us.GoldBadgeCount,
    us.ReputationCategory,
    COUNT(v.Id) AS TotalVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM
    UserStats us
LEFT JOIN
    Votes v ON us.UserId = v.UserId
GROUP BY 
    us.UserId, us.DisplayName, us.RecentPostCount, us.AverageScore, us.GoldBadgeCount, us.ReputationCategory
HAVING 
    COUNT(v.Id) >= 10 
ORDER BY 
    us.AverageScore DESC, us.RecentPostCount DESC;