
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'Expert'
            WHEN Reputation >= 500 THEN 'Veteran'
            ELSE 'Newbie'
        END AS UserType
    FROM 
        Users
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastActivity
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.NetVotes,
    ur.Reputation,
    ur.UserType,
    phd.CloseReopenCount,
    phd.LastActivity
FROM 
    RecentPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (rp.CommentCount > 0 OR rp.NetVotes > 5) 
    AND rp.CreationDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '15 days')
    AND ur.Reputation IS NOT NULL
ORDER BY 
    rp.ViewCount DESC,
    rp.Score DESC,
    phd.CloseReopenCount ASC NULLS FIRST
LIMIT 100;
