WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
TopEntities AS (
    SELECT 
        r.OwnerDisplayName,
        COUNT(r.PostId) AS PostCount,
        SUM(r.Score) AS TotalScore
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
    GROUP BY 
        r.OwnerDisplayName
),
BadgeSummary AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    te.OwnerDisplayName,
    te.PostCount,
    te.TotalScore,
    bs.BadgeCount,
    bs.TotalBadgeClass
FROM 
    TopEntities te
LEFT JOIN 
    BadgeSummary bs ON te.OwnerDisplayName = bs.DisplayName
ORDER BY 
    te.TotalScore DESC, 
    te.PostCount DESC;
