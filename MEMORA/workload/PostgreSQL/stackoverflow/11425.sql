WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.OwnerDisplayName,
    COALESCE(vc.Upvotes, 0) AS Upvotes,
    COALESCE(vc.Downvotes, 0) AS Downvotes,
    pd.TagName
FROM 
    PostDetails pd
LEFT JOIN 
    VoteCounts vc ON pd.PostId = vc.PostId
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC
LIMIT 100;