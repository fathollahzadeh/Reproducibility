
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(r.OwnerPostRank, 0) AS PostsCreated,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, r.OwnerPostRank
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostsCreated,
    u.BadgeCount,
    CASE 
        WHEN u.Reputation = 0 THEN 'No Reputation'
        WHEN u.Reputation BETWEEN 1 AND 500 THEN 'Novice'
        WHEN u.Reputation BETWEEN 501 AND 1000 THEN 'Intermediate'
        ELSE 'Expert' 
    END AS UserLevel,
    STRING_AGG(DISTINCT CONCAT('<', p.Title, '> with ', COALESCE(c.CommentCount, 0), ' comments'), ', ') AS RecentPosts
FROM 
    UserReputation u
LEFT JOIN 
    RankedPosts p ON u.UserId = p.OwnerUserId AND p.OwnerPostRank < 5
LEFT JOIN 
    (SELECT 
        p.OwnerUserId, 
        COUNT(c.Id) AS CommentCount 
     FROM 
        Posts p 
     LEFT JOIN 
        Comments c ON p.Id = c.PostId 
     WHERE 
        p.PostTypeId = 1 
     GROUP BY 
        p.OwnerUserId) c ON u.UserId = c.OwnerUserId
GROUP BY 
    u.UserId, u.Reputation, u.PostsCreated, u.BadgeCount
HAVING 
    u.Reputation IS NOT NULL AND 
    (u.BadgeCount > 0 OR u.PostsCreated > 0)
ORDER BY 
    u.Reputation DESC, u.BadgeCount DESC;
