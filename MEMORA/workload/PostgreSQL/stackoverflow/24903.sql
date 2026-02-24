WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.CommentCount,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No comments'
            WHEN rp.CommentCount < 5 THEN 'Less than 5 comments'
            ELSE 'More than 5 comments'
        END AS CommentSummary,
        CASE 
            WHEN rp.Score IS NULL THEN 'No score'
            WHEN rp.Score > 10 THEN 'High score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium score'
            ELSE 'Low score'
        END AS ScoreCategory,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.CommentSummary,
    fp.ScoreCategory,
    fp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.CommentCount, 
    fp.CommentSummary, fp.ScoreCategory, fp.Tags, u.DisplayName, u.Reputation
ORDER BY 
    fp.ViewCount DESC, fp.CommentCount DESC;