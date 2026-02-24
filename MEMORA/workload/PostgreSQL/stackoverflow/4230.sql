
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleBodyEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        ph.UserId
)
SELECT 
    us.DisplayName, 
    us.Reputation, 
    us.TotalPosts, 
    us.TotalAnswers, 
    us.AvgScore,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    COALESCE(ph.TitleBodyEdits, 0) AS TotalTitleBodyEdits,
    CONCAT('Gold: ', us.GoldBadges, ', Silver: ', us.SilverBadges, ', Bronze: ', us.BronzeBadges) AS BadgeSummary
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryCounts ph ON us.UserId = ph.UserId
WHERE 
    us.Reputation > 1000 AND 
    (us.TotalPosts > 50 OR us.TotalAnswers > 20)
ORDER BY 
    us.Reputation DESC
LIMIT 10;
