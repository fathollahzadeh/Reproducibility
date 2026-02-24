
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM 
        UserStats
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.Score,
    p.CreationDate,
    p.ViewCount,
    p.CommentCount,
    p.BadgeCount
FROM 
    TopUsers u
JOIN 
    PostDetails p ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
WHERE 
    u.RankByReputation <= 10 OR u.RankByPosts <= 10
ORDER BY 
    u.Reputation DESC, u.PostCount DESC;
