WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        AVG(rp.Score) AS AvgScore,
        COUNT(rp.Id) AS PostCount,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
AwardedBadges AS (
    SELECT 
        u.DisplayName,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName, b.Name
)
SELECT 
    tp.OwnerDisplayName,
    tp.AvgScore,
    tp.PostCount,
    tp.TotalViews,
    COALESCE(ab.BadgeName, 'None') AS BadgeName,
    COALESCE(ab.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    AwardedBadges ab ON ab.DisplayName = tp.OwnerDisplayName
ORDER BY 
    tp.AvgScore DESC, tp.TotalViews DESC
LIMIT 10;