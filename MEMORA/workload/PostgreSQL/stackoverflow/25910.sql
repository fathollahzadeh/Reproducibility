WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            WHEN p.PostTypeId = 6 THEN 'Moderator Nomination'
            ELSE 'Other'
        END AS PostType,
        RANK() OVER (PARTITION BY CASE 
                                      WHEN p.PostTypeId = 1 THEN 'Question'
                                      ELSE 'Answer'
                                   END ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        rp.OwnerDisplayName,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.TagCount,
    tp.OwnerDisplayName,
    tp.PostType,
    COUNT(c.Id) AS CommentCount,
    STRING_AGG(b.Name, ', ') AS BadgeNames,
    ARRAY_AGG(DISTINCT linked.LinkTypeId) AS LinkTypeIds
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    PostLinks linked ON tp.PostId = linked.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.TagCount, tp.OwnerDisplayName, tp.PostType
ORDER BY 
    tp.Score DESC;