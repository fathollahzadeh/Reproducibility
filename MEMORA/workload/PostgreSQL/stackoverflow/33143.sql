
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
),

UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

AnswerInfo AS (
    SELECT 
        a.OwnerUserId,
        COUNT(a.Id) AS TotalAnswers,
        SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts a
    WHERE 
        a.PostTypeId = 2
    GROUP BY
        a.OwnerUserId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    COALESCE(ai.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ai.AcceptedAnswers, 0) AS AcceptedAnswers,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    AVG(rp.Score) AS AveragePostScore,
    MAX(rp.CreationDate) AS MostRecentPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    AnswerInfo ai ON u.Id = ai.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 1000 AND (ub.BadgeCount > 0 OR ai.TotalAnswers > 0)
GROUP BY 
    u.DisplayName, u.Reputation, ub.BadgeCount, ub.HighestBadgeClass, ai.TotalAnswers, ai.AcceptedAnswers
ORDER BY 
    u.Reputation DESC, TotalPosts DESC;
