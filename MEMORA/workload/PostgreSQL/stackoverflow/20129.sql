
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(pb.BadgeCount, 0) AS GoldBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pv.TotalVotes,
    pv.UpVotes,
    pv.DownVotes,
    rp.PostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    (pv.UpVotes - pv.DownVotes) / NULLIF(pv.TotalVotes, 0) > 0.5 
ORDER BY 
    GoldBadges DESC, 
    rp.PostRank ASC
LIMIT 10;
