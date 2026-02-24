WITH PostStats AS (
    SELECT 
        p.Id AS PostID,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - p.CreationDate)) AS AgeInSeconds,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostID,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ps.PostID,
    ps.PostTypeId,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.AgeInSeconds,
    ps.OwnerReputation,
    tp.TagCount,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes
FROM 
    PostStats ps
LEFT JOIN 
    TaggedPosts tp ON ps.PostID = tp.PostID
LEFT JOIN 
    VoteStats vs ON ps.PostID = vs.PostId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;