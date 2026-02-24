WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS TotalQuestions,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AverageViewCount,
    MAX(rp.CreationDate) AS LastPostDate
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
WHERE 
    up.Reputation >= 1000
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, up.GoldBadges, up.SilverBadges, up.BronzeBadges
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalScore DESC, AverageViewCount DESC;
