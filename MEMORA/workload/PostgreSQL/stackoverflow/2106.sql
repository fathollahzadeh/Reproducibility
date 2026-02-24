WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.Class, 0) AS BadgeClass,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class
         FROM Badges
         GROUP BY UserId) b ON u.Id = b.UserId
),
PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.Reputation,
        ur.BadgeClass,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.PostId = ur.UserId
    WHERE 
        rp.UserPostRank <= 5
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.Reputation,
    ps.BadgeClass,
    COALESCE(CASE WHEN ps.CommentCount = 0 THEN 'No Comments' ELSE 'Has Comments' END, 'Unknown') AS CommentStatus
FROM 
    PostScores ps
ORDER BY 
    ps.Score DESC, ps.Reputation DESC
LIMIT 20;