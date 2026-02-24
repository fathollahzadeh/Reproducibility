WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(*) > 0
),
UserBadges AS (
    SELECT 
        u.Id,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostsWithBadges AS (
    SELECT 
        pu.OwnerDisplayName,
        pu.PostCount,
        pu.TotalScore,
        ub.BadgeCount
    FROM 
        TopUsers pu
    LEFT JOIN 
        UserBadges ub ON pu.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.Id)
)
SELECT 
    p.OwnerDisplayName,
    p.PostCount,
    p.TotalScore,
    COALESCE(p.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN p.BadgeCount >= 5 THEN 'Top Contributor'
        WHEN p.BadgeCount >= 3 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    PostsWithBadges p
ORDER BY 
    p.TotalScore DESC
LIMIT 10;