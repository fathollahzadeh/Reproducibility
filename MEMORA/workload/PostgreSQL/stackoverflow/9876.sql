
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.PostTypeId = 1 AND (p.ClosedDate IS NULL OR p.ClosedDate > '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        UPPER(u.Location) AS Location,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Location
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    ud.DisplayName AS OwnerDisplayName,
    ud.Reputation AS OwnerReputation,
    ud.Location,
    rp.VoteCount,
    rp.CreationDate,
    rp.ScoreRank,
    ud.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserDetails ud ON rp.OwnerUserId = ud.UserId
WHERE 
    rp.ScoreRank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
