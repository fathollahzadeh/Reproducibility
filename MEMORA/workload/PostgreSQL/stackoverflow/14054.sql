
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, u.UpVotes, u.DownVotes
),
TopPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Id AS PostId,
        p.Title,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.LastAccessDate,
    us.UpVotes,
    us.DownVotes,
    us.PostCount,
    us.CommentCount,
    tp.PostId,
    tp.Title,
    tp.Score
FROM 
    UserStatistics us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId AND tp.PostRank = 1
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
