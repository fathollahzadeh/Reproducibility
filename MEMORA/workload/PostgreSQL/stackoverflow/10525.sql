WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(ph.RevisionGUID, 'N/A') AS LatestRevision,
        COALESCE(ph.CreationDate, '1970-01-01') AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
)

SELECT 
    PostId,
    Title,
    PostType,
    OwnerDisplayName,
    OwnerReputation,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    LatestRevision,
    LastEditDate,
    RANK() OVER (ORDER BY Score DESC) AS ScoreRank
FROM 
    PostSummary
ORDER BY 
    Score DESC
LIMIT 100;