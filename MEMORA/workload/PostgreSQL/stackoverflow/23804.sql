WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score >= 0
        AND p.PostTypeId IN (1, 2)  
), 

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS TotalViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5  
), 

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        MAX(u.Reputation) AS MaxReputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id 
    HAVING 
        MAX(u.Reputation) IS NOT NULL
), 

PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    ts.TagName,
    ts.PostCount,
    ts.TotalViewCount,
    ts.AverageScore,
    ur.MaxReputation,
    ur.BadgeCount,
    phc.EditCount,
    phc.LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON ts.PostCount > 10
JOIN 
    UserReputation ur ON ur.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryCounts phc ON phc.PostId = rp.PostId
WHERE 
    (phc.EditCount IS NULL OR phc.EditCount <= 3)  
    AND (rp.Score - COALESCE(phc.EditCount, 0) > 0)  
    AND rp.RecentRank <= 10  
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;