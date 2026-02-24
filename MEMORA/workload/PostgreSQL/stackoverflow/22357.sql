
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.ViewCount > 0
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, u.DisplayName, p.CreationDate
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.ExcerptPostId = p.Id
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    tc.PostCount AS TagPostCount,
    ur.Reputation,
    ur.ReputationRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON rp.Title LIKE '%' || tc.TagName || '%'  
LEFT JOIN 
    UserReputation ur ON rp.OwnerDisplayName = ur.DisplayName
WHERE 
    rp.rn <= 5  
    AND (ur.Reputation IS NULL OR ur.Reputation > 1000)  
ORDER BY 
    rp.CreationDate DESC, rp.VoteCount DESC
FETCH FIRST 50 ROWS ONLY;
