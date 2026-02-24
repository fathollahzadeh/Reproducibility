WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(NULLIF(p.Tags, ''), 'No Tags') ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2023-01-01' 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    (
        SELECT COUNT(*) 
        FROM Comments c 
        WHERE c.PostId = rp.PostId
    ) AS CommentCount,
    (
        SELECT 
            STRING_AGG(DISTINCT CONCAT(b.Name, ' (', b.Class, ')'), '; ') 
        FROM 
            Badges b 
        WHERE 
            b.UserId = rp.OwnerUserId
    ) AS UserBadges
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank <= 5 
ORDER BY 
    rp.CreationDate DESC;