WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(AnswerCount, 0) AS AnswerCount,
        COALESCE(CommentCount, 0) AS CommentCount,
        COALESCE(ViewCount, 0) AS ViewCount,
        COALESCE(Score, 0) AS Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AnswerCount, p.CommentCount, 
        p.ViewCount, p.Score, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.AnswerCount,
    ps.CommentCount,
    ps.ViewCount,
    ps.Score,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ps.Upvotes,
    ps.Downvotes,
    (ps.Upvotes - ps.Downvotes) AS NetVotes
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 100;