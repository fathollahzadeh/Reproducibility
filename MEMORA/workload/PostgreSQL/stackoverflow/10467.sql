WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.LastActivityDate,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerReputation,
    pd.OwnerDisplayName,
    COALESCE(vs.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(vs.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.LastActivityDate
FROM 
    PostDetails pd
LEFT JOIN 
    VoteStats vs ON pd.PostId = vs.PostId
LEFT JOIN 
    CommentCounts cc ON pd.PostId = cc.PostId
ORDER BY 
    pd.CreationDate DESC;