
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostViews AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopAnswerers AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 AND 
        p.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    ub.BadgeNames,
    pv.TotalViews,
    pv.PostCount,
    COALESCE(ta.AnswerCount, 0) AS AcceptedAnswerCount,
    CASE 
        WHEN ub.BadgeCount > 5 THEN 'Veteran'
        WHEN ub.BadgeCount BETWEEN 3 AND 5 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserRank
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostViews pv ON u.Id = pv.OwnerUserId
LEFT JOIN 
    TopAnswerers ta ON u.Id = ta.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    UserRank DESC, 
    ub.BadgeCount DESC, 
    pv.TotalViews DESC;
