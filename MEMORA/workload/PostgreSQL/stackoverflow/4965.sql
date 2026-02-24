WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreated,
        MAX(u.LastAccessDate) AS LastAccessed
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostWithVoteCounts AS (
    SELECT 
        p.Id,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ur.Reputation,
    ur.BadgeCount,
    COALESCE(pvc.UpVotesCount, 0) AS UpVotes,
    COALESCE(pvc.DownVotesCount, 0) AS DownVotes,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High Reputation'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN rp.PostRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRating
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON ur.UserId = rp.PostId
LEFT JOIN 
    PostWithVoteCounts pvc ON pvc.Id = rp.PostId
WHERE 
    ur.BadgeCount > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;