
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.UpVotes,
        rp.DownVotes
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    ub.UserId,
    ub.BadgeCount,
    ub.HighestBadge
FROM TopPosts tp
LEFT JOIN UserBadges ub ON tp.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
WHERE tp.ViewCount > (SELECT AVG(ViewCount) FROM TopPosts)
ORDER BY tp.ViewCount DESC;
