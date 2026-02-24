
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserID = ub.UserId
LEFT JOIN 
    RankedPosts rp ON tu.UserID = rp.OwnerUserId AND rp.PostRank <= 3  
WHERE 
    tu.UserRank <= 10  
ORDER BY 
    tu.TotalScore DESC, 
    rp.ViewCount DESC;
