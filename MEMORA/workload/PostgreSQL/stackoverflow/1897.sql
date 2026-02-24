
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
        AND u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopPosts AS (
    SELECT 
        p.OwnerUserId, 
        p.Title, 
        p.Score, 
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.ViewCount > 100 
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    tp.Title,
    tp.Score
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = tp.OwnerUserId
WHERE 
    (tp.Rank <= 3 OR tp.Rank IS NULL)
ORDER BY 
    us.Reputation DESC, us.PostCount DESC, tp.Score DESC;
