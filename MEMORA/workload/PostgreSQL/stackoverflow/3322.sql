WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
RecentPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM RankedPosts rp
    WHERE rp.rn <= 5 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    pvs.UpVotes,
    pvs.DownVotes,
    ub.BadgeCount
FROM RecentPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostVoteStats pvs ON rp.Id = pvs.PostId
WHERE 
    ub.BadgeCount IS NOT NULL AND 
    pvs.UpVotes > pvs.DownVotes
ORDER BY 
    rp.CreationDate DESC;