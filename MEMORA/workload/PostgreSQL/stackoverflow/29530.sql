WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        ScoreRank
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5 
)
SELECT 
    tq.Title,
    tq.OwnerDisplayName,
    tq.CreationDate,
    tq.ViewCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM 
    TopQuestions tq
LEFT JOIN 
    Comments c ON tq.PostId = c.PostId
LEFT JOIN 
    Posts p ON tq.PostId = p.Id
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(tq.Tags, '<>')) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    tq.Title, tq.OwnerDisplayName, tq.CreationDate, tq.ViewCount
ORDER BY 
    tq.ViewCount DESC;