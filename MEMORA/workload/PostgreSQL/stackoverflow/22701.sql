
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AveragePostScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        STRING_AGG(CONCAT(ph.Comment, ': ', ph.CreationDate), '; ' ORDER BY ph.CreationDate) AS Edits
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11) 
    GROUP BY 
        ph.UserId, ph.PostId
),
UserRankings AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.TotalPosts,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        (0.2 * us.TotalPosts + 0.4 * COALESCE(ub.GoldBadges, 0) + 0.3 * COALESCE(ub.SilverBadges, 0) + 0.1 * COALESCE(ub.BronzeBadges, 0)) AS RankingScore
    FROM 
        Users u
    JOIN 
        PostStatistics us ON u.Id = us.OwnerUserId
    LEFT JOIN 
        UserBadgeStats ub ON u.Id = ub.UserId
)
SELECT 
    ur.DisplayName,
    COALESCE(ur.TotalPosts, 0) AS TotalPosts,
    COALESCE(ur.GoldBadges, 0) AS GoldBadges,
    COALESCE(ur.SilverBadges, 0) AS SilverBadges,
    COALESCE(ur.BronzeBadges, 0) AS BronzeBadges,
    ur.RankingScore,
    STRING_AGG(DISTINCT CONCAT(phd.Edits, ' (Post ID: ', phd.PostId, ')'), '; ') AS PostEditsSummary
FROM 
    UserRankings ur
LEFT JOIN 
    PostHistoryDetails phd ON ur.Id = phd.UserId
WHERE 
    ur.RankingScore > (
        SELECT AVG(RankingScore) FROM UserRankings 
        WHERE TotalPosts > 10
    )
GROUP BY 
    ur.DisplayName, ur.TotalPosts, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges, ur.RankingScore
ORDER BY 
    ur.RankingScore DESC 
LIMIT 10;
