WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreQuestions,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id
), BadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalQuestions,
        us.PositiveScoreQuestions,
        us.NegativeScoreQuestions,
        us.AvgViewCount,
        COALESCE(bc.TotalBadges, 0) AS TotalBadges
    FROM 
        UserStats us
    LEFT JOIN 
        BadgeCount bc ON us.UserId = bc.UserId
    ORDER BY 
        us.TotalQuestions DESC,
        us.AvgViewCount DESC
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.ViewCount,
    fps.Score,
    us.DisplayName,
    us.TotalQuestions,
    us.PositiveScoreQuestions,
    us.NegativeScoreQuestions,
    us.TotalBadges
FROM 
    RankedPosts fps
JOIN 
    FinalStats us ON fps.PostId = us.UserId 
WHERE 
    fps.UserRank <= 3
ORDER BY 
    us.TotalBadges DESC,
    fps.Score DESC;
