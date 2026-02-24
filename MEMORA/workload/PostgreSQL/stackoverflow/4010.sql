
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.BadgeCount,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.rn = 1 
    AND rp.Score IS NOT NULL
ORDER BY 
    PostStatus DESC, 
    rp.Score DESC;
