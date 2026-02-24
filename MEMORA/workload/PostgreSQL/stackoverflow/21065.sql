WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS total_count
    FROM
        Posts p
    WHERE
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    up.DisplayName AS OwnerDisplayName,
    bt.Name AS BadgeName,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = pp.PostId) AS CommentCount,
    CASE 
        WHEN pp.PostTypeId = 1 THEN 'Question'
        WHEN pp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    CASE 
        WHEN pp.ViewCount IS NULL THEN 'No views recorded'
        ELSE CAST(NULLIF(pp.ViewCount, 0) AS VARCHAR)
    END AS ViewCountDescription,
    COALESCE(
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2), 
        0
    ) AS Upvotes  
FROM 
    RankedPosts pp
LEFT JOIN 
    Users up ON pp.PostId = up.Id
LEFT JOIN 
    Badges bt ON up.Id = bt.UserId
WHERE 
    pp.rn <= 10
    AND pp.PostTypeId IN (1, 2)
    AND (bt.Class IS NULL OR bt.Class < 3)
ORDER BY 
    pp.Score DESC,
    pp.ViewCount DESC;