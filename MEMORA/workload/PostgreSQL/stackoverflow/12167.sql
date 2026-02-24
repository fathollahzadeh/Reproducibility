
WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.PostTypeId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    uv.TotalVotes,
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.UniqueVoters,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    COUNT(b.Id) AS UserBadgeCount
FROM 
    Users u
JOIN 
    UserVotes uv ON u.Id = uv.UserId
JOIN 
    PostStats ps ON u.Id = ps.UniqueVoters
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName, u.Reputation, uv.TotalVotes, ps.PostId, ps.PostTypeId, 
    ps.CommentCount, ps.UniqueVoters, ps.UpVotes, ps.DownVotes
ORDER BY 
    u.Reputation DESC, ps.UpVotes DESC;
