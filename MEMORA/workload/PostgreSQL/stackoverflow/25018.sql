WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 
),
TagCount AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.Score,
    fp.OwnerDisplayName,
    COALESCE(tc.TagCount, 0) AS TagCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
LEFT JOIN 
    TagCount tc ON fp.PostId = tc.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.LastActivityDate, fp.Score, fp.OwnerDisplayName, tc.TagCount
ORDER BY 
    UpvoteCount DESC, CommentCount DESC, fp.CreationDate DESC
LIMIT 50;