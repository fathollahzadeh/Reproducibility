
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS TotalComments,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, 
        u.DisplayName, u.Reputation
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.FavoriteCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.TotalComments,
    vs.UpVotes,
    vs.DownVotes,
    vs.CloseVotes,
    pd.LastVoteDate
FROM 
    PostDetails pd
LEFT JOIN 
    VoteStatistics vs ON pd.PostId = vs.PostId
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC
LIMIT 100;
