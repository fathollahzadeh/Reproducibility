WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 10
),
TopScores AS (
    SELECT 
        rp.OwnerDisplayName,
        SUM(rp.Score) AS TotalScore,
        COUNT(rp.PostId) AS PostCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
BadgeCounts AS (
    SELECT 
        u.DisplayName AS OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ts.OwnerDisplayName,
    ts.TotalScore,
    ts.PostCount,
    bc.BadgeCount
FROM 
    TopScores ts
LEFT JOIN 
    BadgeCounts bc ON ts.OwnerDisplayName = bc.OwnerDisplayName
ORDER BY 
    ts.TotalScore DESC, 
    ts.PostCount DESC
LIMIT 10;
