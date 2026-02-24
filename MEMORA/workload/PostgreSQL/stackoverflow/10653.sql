
WITH UserStatistics AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes
    FROM 
        Users
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01'
), 
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    us.UserId,
    us.Reputation,
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.Tags,
    ps.OwnerDisplayName,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes
FROM 
    UserStatistics us
JOIN 
    PostStatistics ps ON us.UserId = ps.OwnerUserId
LEFT JOIN 
    VoteStatistics vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;
