WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
), 
TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
    GROUP BY 
        rp.OwnerDisplayName
), 
BadgedUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    t.OwnerDisplayName,
    t.PostCount,
    t.TotalScore,
    t.TotalViews,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts t
LEFT JOIN 
    BadgedUsers b ON t.OwnerDisplayName = b.DisplayName
ORDER BY 
    t.TotalScore DESC, t.TotalViews DESC
LIMIT 10;