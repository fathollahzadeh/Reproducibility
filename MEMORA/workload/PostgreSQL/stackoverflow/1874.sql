WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score IS NOT NULL
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 5
), 
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.TotalViews,
    ub.BadgeNames,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    r.RowNum,
    r.PostCount
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
JOIN 
    RankedPosts r ON tu.UserId = r.OwnerUserId AND r.RowNum = 1
JOIN 
    Posts p ON p.Id = r.Id
WHERE 
    p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    tu.TotalViews DESC NULLS LAST, 
    tu.Reputation DESC;