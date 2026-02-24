
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
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
)
SELECT 
    us.DisplayName,
    us.TotalVotes,
    us.UpVotes AS UserUpVotes,
    us.DownVotes AS UserDownVotes,
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes
FROM 
    UserVoteStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostStats ps ON p.Id = ps.PostId
ORDER BY 
    us.TotalVotes DESC, 
    ps.CommentCount DESC
LIMIT 100;
