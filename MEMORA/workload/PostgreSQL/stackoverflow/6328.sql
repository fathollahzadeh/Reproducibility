WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
FrequentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY u.Id, u.DisplayName
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.CommentCount,
    fu.DisplayName AS FrequentUser,
    tb.BadgeCount
FROM RankedPosts rp
JOIN FrequentUsers fu ON rp.PostId IN (SELECT PostId FROM Votes v WHERE v.UserId = fu.UserId)
LEFT JOIN TopBadges tb ON fu.UserId = tb.UserId
WHERE rp.rn <= 5
ORDER BY rp.Score DESC, rp.ViewCount DESC, tb.BadgeCount DESC;