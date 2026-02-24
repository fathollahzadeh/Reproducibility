WITH UserVotes AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        uv.VoteCount,
        uv.UpVotes,
        uv.DownVotes
    FROM 
        Users u
    JOIN 
        UserVotes uv ON u.Id = uv.UserId
    ORDER BY 
        uv.VoteCount DESC
    LIMIT 10
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        COALESCE(a.UserCount, 0) AS ActiveUsers
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(DISTINCT UserId) AS UserCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) a ON p.Id = a.PostId 
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.ActiveUsers
FROM 
    TopUsers tu
JOIN 
    PostStats ps ON ps.AnswerCount > 0  
ORDER BY 
    tu.VoteCount DESC, ps.ViewCount DESC;