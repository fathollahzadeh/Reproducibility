WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        AVG(v.BountyAmount) AS AverageBounty,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM RankedPosts rp
    LEFT JOIN Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    WHERE rp.UserPostRank = 1
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC, AnswerCount DESC) AS Rank
    FROM PostMetrics
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.AverageBounty,
    tp.CommentCount,
    tp.LastEditDate
FROM TopPosts tp
WHERE tp.Rank <= 10
ORDER BY tp.Rank;