
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Author,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    ua.DisplayName AS TopUser,
    ua.BadgeCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM TopPosts tp
JOIN UserActivity ua ON tp.Author = ua.DisplayName
ORDER BY tp.Score DESC, tp.ViewCount DESC;
