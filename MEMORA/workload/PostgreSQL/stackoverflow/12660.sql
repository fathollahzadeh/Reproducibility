WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(ps.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ps ON p.Id = ps.ParentId AND ps.PostTypeId = 2
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
)

SELECT 
    u.DisplayName,
    u.VoteCount,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount
FROM 
    UserVoteStats u
JOIN 
    PostStats p ON u.UserId = p.PostId
ORDER BY 
    u.VoteCount DESC, p.Score DESC;