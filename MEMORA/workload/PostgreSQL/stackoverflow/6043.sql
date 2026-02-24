
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(p.Score), 0) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ut.TotalViews,
    ut.BadgeCount,
    ut.AverageScore,
    pt.Tag AS PopularTag
FROM 
    RankedPosts rp
JOIN 
    UserStats ut ON rp.OwnerUserId = ut.UserId
LEFT JOIN 
    PopularTags pt ON pt.Tag IS NOT NULL
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC, ut.TotalViews DESC
LIMIT 100;
