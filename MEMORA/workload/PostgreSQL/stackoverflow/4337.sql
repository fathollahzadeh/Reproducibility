WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVoteInfo AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    up.BadgeCount,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    COALESCE(up.BadgeNames, 'No Badges') AS UserBadges
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostID = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges up ON u.Id = up.UserId
LEFT JOIN 
    PostVoteInfo pv ON p.Id = pv.PostId
WHERE 
    rp.rn <= 5
  AND 
    (u.Reputation > 1000 OR u.Location IS NOT NULL)
ORDER BY 
    p.Score DESC, p.ViewCount DESC;