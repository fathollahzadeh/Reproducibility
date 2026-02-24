
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        pi.PostId,
        pi.Title,
        pi.CreationDate,
        pi.Score,
        pi.CommentCount,
        pi.UpVoteCount,
        pi.DownVoteCount
    FROM 
        UserStats us
    JOIN 
        PostInteraction pi ON us.UserId = pi.PostId 
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.BadgeCount,
    cs.Title,
    cs.CreationDate,
    cs.Score,
    cs.CommentCount,
    cs.UpVoteCount,
    cs.DownVoteCount
FROM 
    CombinedStats cs
WHERE 
    cs.Reputation > 1000
ORDER BY 
    cs.Reputation DESC, 
    cs.Score DESC;
