WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
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
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalVotes,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes,
    p.PostId,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    p.CommentCount,
    p.UpVotes AS PostUpVotes,
    p.DownVotes AS PostDownVotes
FROM 
    UserVoteStats u
JOIN 
    PostStats p ON u.UserId = p.PostId 
ORDER BY 
    u.TotalVotes DESC, p.Score DESC;