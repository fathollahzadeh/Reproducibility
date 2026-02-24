
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        us.DisplayName,
        us.UserId,
        rp.CreationDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CommentCount,
    us.Reputation,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    CASE
        WHEN us.Reputation > 1000 THEN 'High Reputation'
        WHEN us.Reputation BETWEEN 501 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.UserId = us.UserId
ORDER BY 
    tp.Score DESC, 
    us.Reputation DESC
LIMIT 10;
