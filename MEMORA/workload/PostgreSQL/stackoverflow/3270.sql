WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(b.Count, 0) AS BadgeCount,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT UserId, SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
                        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes 
         FROM Votes v 
         JOIN VoteTypes vt ON v.VoteTypeId = vt.Id 
         GROUP BY v.UserId) v ON u.Id = v.UserId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.NetVotes,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        WHEN rp.PostRank <= 5 THEN 'High Ranking Post'
        ELSE 'Other' 
    END AS PostCategory
FROM 
    UserReputation ur
JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE 
    ur.Reputation > 1000
    AND (rp.CommentCount > 5 OR rp.Score < 0)
ORDER BY 
    ur.Reputation DESC, 
    rp.Score DESC
LIMIT 50;