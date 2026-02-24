WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.RankScore,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.GoldBadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.GoldBadgeCount,
    CASE 
        WHEN tp.GoldBadgeCount > 0 THEN 'Gold Badge Holder'
        ELSE 'No Gold Badge'
    END AS BadgeStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC
LIMIT 100;