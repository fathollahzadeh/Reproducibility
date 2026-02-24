WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(b.Class) AS AvgBadgeClass,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM 
        UserBadges ub
    INNER JOIN 
        RecentPosts p ON ub.UserId = p.OwnerUserId
    GROUP BY 
        ub.UserId, ub.DisplayName
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    ub.BadgeCount,
    ub.AvgBadgeClass,
    ub.BadgeNames,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    tu.ScoreRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalScore, ub.BadgeCount, ub.AvgBadgeClass, ub.BadgeNames
ORDER BY 
    tu.TotalScore DESC;