
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostAggregates AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS Owner,
        ur.Reputation,
        ur.Upvotes,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.ViewCount,
    pa.Owner,
    pa.Reputation,
    pa.Upvotes,
    pa.BadgeCount,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM 
    PostAggregates pa
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) c ON pa.PostId = c.PostId
ORDER BY 
    pa.Score DESC, 
    pa.ViewCount DESC;
