
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND 
        p.PostTypeId = 1
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
    HAVING 
        COUNT(p.Id) > 5 
    ORDER BY 
        UpVotes DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views Yet'
        ELSE CAST(rp.ViewCount AS VARCHAR)
    END AS ViewCount,
    COALESCE(bp.BadgeCount, 0) AS BadgeCount,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    RecentPosts rp
JOIN 
    TopUsers u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) bp ON u.UserId = bp.UserId
WHERE 
    rp.RecentRank = 1
ORDER BY 
    u.Reputation DESC, 
    rp.Score DESC
LIMIT 100;
