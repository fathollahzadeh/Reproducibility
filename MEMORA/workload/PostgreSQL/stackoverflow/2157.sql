
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC) AS PostRank
    FROM 
        PostStatistics ps
)
SELECT 
    um.UserId,
    um.DisplayName,
    um.Reputation,
    um.PostCount,
    um.TotalBounty,
    um.Upvotes,
    um.Downvotes,
    tp.Title,
    tp.ViewCount,
    tp.PostRank
FROM 
    UserMetrics um
JOIN 
    TopPosts tp ON um.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = tp.PostId)
WHERE 
    um.Reputation > 100 AND tp.PostRank <= 10
ORDER BY 
    um.Reputation DESC, tp.ViewCount DESC;
