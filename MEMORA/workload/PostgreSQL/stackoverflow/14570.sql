WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        u.CreationDate AS OwnerCreationDate
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
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.OwnerCreationDate,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(vs.AcceptedVotes, 0) AS TotalAcceptedVotes,
    COALESCE(cs.TotalComments, 0) AS TotalComments
FROM 
    PostStats ps
LEFT JOIN 
    VoteStats vs ON ps.PostId = vs.PostId
LEFT JOIN 
    CommentStats cs ON ps.PostId = cs.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC 
LIMIT 100;