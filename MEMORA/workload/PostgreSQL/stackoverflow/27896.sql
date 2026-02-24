
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.Tags,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0 
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)

SELECT 
    f.PostId,
    f.Title,
    f.OwnerDisplayName,
    f.ViewCount,
    f.Score,
    f.AnswerCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes, 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes 
FROM 
    FilteredPosts f
LEFT JOIN 
    Comments c ON f.PostId = c.PostId
LEFT JOIN 
    PostHistory ph ON f.PostId = ph.PostId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(f.Tags, ',')) AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON TRIM(tag_array) = t.TagName
LEFT JOIN 
    Votes v ON f.PostId = v.PostId
GROUP BY 
    f.PostId, f.Title, f.OwnerDisplayName, f.ViewCount, f.Score, f.AnswerCount
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
