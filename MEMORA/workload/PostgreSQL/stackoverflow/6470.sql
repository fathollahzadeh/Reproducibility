
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        pp.PostCount,
        pp.TotalScore,
        pp.AverageViews
    FROM 
        UserBadgeCounts ub
    JOIN 
        PopularPosts pp ON ub.UserId = pp.OwnerUserId
    ORDER BY 
        pp.TotalScore DESC, ub.BadgeCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.PostCount,
    tu.TotalScore,
    tu.AverageViews
FROM 
    TopUsers tu
JOIN 
    PostTypes pt ON pt.Id = (
        SELECT 
            p.PostTypeId 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId 
        ORDER BY 
            p.CreationDate DESC 
        LIMIT 1
    )
WHERE 
    pt.Name IN ('Question', 'Answer')
ORDER BY 
    tu.TotalScore DESC;
