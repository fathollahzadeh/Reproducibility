
WITH UserVoteStats AS (
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
    GROUP BY 
        p.Id, p.OwnerUserId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        us.TotalVotes,
        us.UpVotes AS UserUpVotes,
        us.DownVotes AS UserDownVotes,
        p.PostId,
        p.CommentCount,
        p.UpVotes AS PostUpVotes,
        p.DownVotes AS PostDownVotes
    FROM 
        UserVoteStats us
    JOIN 
        Users u ON us.UserId = u.Id
    JOIN 
        PostStats p ON p.OwnerUserId = u.Id
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalVotes,
    UserUpVotes,
    UserDownVotes,
    PostId,
    CommentCount,
    PostUpVotes,
    PostDownVotes
FROM 
    FinalStats
ORDER BY 
    Reputation DESC, TotalVotes DESC;
