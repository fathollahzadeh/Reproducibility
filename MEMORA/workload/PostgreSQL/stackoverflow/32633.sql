WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalPositiveScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 50  
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    up.PostId, 
    up.Title, 
    up.CreationDate, 
    ur.Reputation,
    ur.PostCount,
    ur.TotalPositiveScore,
    ur.AverageViewCount,
    pt.TagPostCount,
    cp.CloseCount,
    cp.LastClosedDate
FROM 
    RankedPosts up
JOIN 
    UserReputation ur ON up.OwnerUserId = ur.UserId
LEFT JOIN 
    PopularTags pt ON up.Title LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.PostId
WHERE 
    up.rn = 1  
ORDER BY 
    ur.Reputation DESC, 
    up.Score DESC NULLS LAST
LIMIT 100;