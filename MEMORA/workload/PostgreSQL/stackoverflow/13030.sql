
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.AcceptedAnswerId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.BadgeCount,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    p.AcceptedAnswerId,
    p.CommentCount,
    p.HistoryCount
FROM 
    UserStats u
JOIN 
    PostStats p ON u.UserId = p.AcceptedAnswerId
ORDER BY 
    u.Reputation DESC, p.Score DESC
FETCH FIRST 100 ROWS ONLY;
