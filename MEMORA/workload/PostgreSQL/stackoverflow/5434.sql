WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerUserId,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
),
ExtendedPosts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.OwnerUserId,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM TopPosts tp
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.OwnerUserId, tp.OwnerDisplayName
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.AnswerCount,
    ep.CommentCount,
    ep.OwnerUserId,
    ep.OwnerDisplayName,
    ep.TotalComments,
    ep.UpVotes,
    ep.DownVotes,
    CASE 
        WHEN ep.Score > 50 THEN 'High Score'
        WHEN ep.Score BETWEEN 20 AND 50 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM ExtendedPosts ep
ORDER BY ep.Score DESC;