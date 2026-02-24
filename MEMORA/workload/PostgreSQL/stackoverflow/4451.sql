
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTH'
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.TotalPosts,
    us.TotalComments,
    COALESCE(pe.PostId, -1) AS MostEngagedPost,
    COALESCE(pe.Title, 'No Posts') AS PostTitle,
    COALESCE(pe.Score, 0) AS PostScore,
    COALESCE(pe.ViewCount, 0) AS PostViewCount,
    pe.HasAcceptedAnswer,
    pe.ScoreRank
FROM 
    UserStats us
LEFT JOIN 
    PostEngagement pe ON us.UserId = pe.PostId
WHERE 
    us.TotalComments > 0
ORDER BY 
    us.TotalPosts DESC, 
    us.DisplayName ASC;
