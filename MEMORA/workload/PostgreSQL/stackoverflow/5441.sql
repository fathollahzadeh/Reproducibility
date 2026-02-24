
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        p.LastActivityDate, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(ph.Id) AS EditCount
    FROM 
        Users u 
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id 
    GROUP BY 
        u.Id, u.Reputation
), PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, ',')) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        UNNEST(STRING_TO_ARRAY(Tags, ',')) 
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    ur.Reputation, 
    ur.EditCount, 
    pt.TagName AS PopularTag
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
CROSS JOIN 
    PopularTags pt
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
