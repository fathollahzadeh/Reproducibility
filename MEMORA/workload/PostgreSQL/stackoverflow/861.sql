
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        tu.UserId, 
        tu.DisplayName, 
        tu.PostCount, 
        tu.TotalScore, 
        ub.Badges,
        ub.BadgeCount
    FROM 
        TopUsers tu
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.PostCount, 
    fr.TotalScore,
    COALESCE(fr.Badges, 'No badges') AS Badges,
    fr.BadgeCount,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS TopPostDate
FROM 
    FinalResults fr
LEFT JOIN 
    RankedPosts rp ON fr.UserId = rp.OwnerUserId AND rp.PostRank = 1
ORDER BY 
    fr.TotalScore DESC, 
    fr.PostCount DESC;
