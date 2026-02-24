WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tu.PostCount,
    tu.TotalScore,
    COALESCE(b.Count, 0) AS BadgeCount,
    COALESCE((SELECT AVG(CAST(Score AS FLOAT)) FROM RankedPosts r WHERE r.OwnerUserId = u.Id), 0) AS AveragePostScore
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.OwnerUserId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS Count 
     FROM Badges 
     GROUP BY UserId) b ON b.UserId = u.Id
WHERE 
    u.Reputation > 1000
ORDER BY 
    tu.TotalScore DESC, 
    u.DisplayName ASC;
