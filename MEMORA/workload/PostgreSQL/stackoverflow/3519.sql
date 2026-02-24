
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.Score > 10
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High'
            WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users U
), PostsWithTags AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        COALESCE(NULLIF(t.TagName, ''), 'No Tags') AS TagName
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    up.ReputationCategory,
    pt.TagName,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    RankedPosts rp
JOIN 
    UserReputation up ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
JOIN 
    PostsWithTags pt ON pt.Id = rp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
