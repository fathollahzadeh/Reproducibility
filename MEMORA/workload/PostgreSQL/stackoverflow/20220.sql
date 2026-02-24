WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostRankings AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.ViewCount > 0
    GROUP BY 
        p.Id, p.OwnerUserId, p.Score, p.CreationDate
    HAVING 
        COUNT(DISTINCT c.Id) > 2 OR COUNT(DISTINCT v.Id) > 5
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.LastAccessDate,
        COALESCE(SUM(ps.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName, u.LastAccessDate
)
SELECT 
    us.UserId,
    us.DisplayName AS UserName,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pr.Score, 0) AS TopPostScore,
    pr.ScoreRank,
    au.TotalScore AS UserTotalScore,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    UserStats us
LEFT JOIN 
    PostRankings pr ON us.UserId = pr.OwnerUserId AND pr.ScoreRank = 1
LEFT JOIN 
    PostHistory ph ON ph.UserId = us.UserId
LEFT JOIN 
    ActiveUsers au ON us.UserId = au.UserId
WHERE 
    us.Reputation > 100 OR us.BadgeCount > 5
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.BadgeCount, 
    us.GoldBadges, us.SilverBadges, us.BronzeBadges, 
    pr.Score, pr.ScoreRank, au.TotalScore
ORDER BY 
    UserTotalScore DESC, us.Reputation DESC
LIMIT 25
OFFSET 0;