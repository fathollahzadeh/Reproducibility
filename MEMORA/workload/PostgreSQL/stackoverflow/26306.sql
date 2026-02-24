
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN u.Reputation >= 1000 THEN 1 ELSE 0 END ORDER BY p.Score DESC) AS Rnk
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
DistinctTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId, b.Name
),
BadgeDetails AS (
    SELECT 
        ub.UserId,
        u.DisplayName,
        tb.Name AS BadgeName,
        tb.BadgeCount
    FROM 
        (SELECT UserId, SUM(BadgeCount) AS TotalBadges 
         FROM TopBadges 
         GROUP BY UserId) ub
    JOIN 
        Users u ON ub.UserId = u.Id
    JOIN 
        TopBadges tb ON ub.UserId = tb.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    dt.TagName,
    bd.BadgeName,
    bd.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    DistinctTags dt ON rp.Tags LIKE '%' || dt.TagName || '%'
LEFT JOIN 
    BadgeDetails bd ON rp.OwnerUserId = bd.UserId
WHERE 
    rp.Rnk = 1 
ORDER BY 
    rp.CreationDate DESC;
