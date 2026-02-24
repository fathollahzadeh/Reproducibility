WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        LEAD(p.Score) OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS NextScore,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score < 0 THEN 'Low Score'
            ELSE 'Valid Score'
        END AS ScoreCategory
    FROM Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY p.Id
),
FinalResults AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.ViewCount,
        pp.Score,
        pp.AnswerCount,
        pp.CommentCount,
        pi.TotalCommentScore,
        pi.TotalBountyAmount,
        pp.RankScore,
        pp.NextScore,
        pp.ScoreCategory,
        CASE 
            WHEN pp.RankScore = 1 THEN 'Top Post'
            WHEN pp.RankScore <= 5 THEN 'Top 5 Post'
            ELSE 'Regular Post'
        END AS Category
    FROM RankedPosts pp
    LEFT JOIN PostInteractions pi ON pp.PostId = pi.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.AnswerCount,
    fr.CommentCount,
    fr.TotalCommentScore,
    fr.TotalBountyAmount,
    fr.RankScore,
    fr.NextScore,
    fr.ScoreCategory,
    fr.Category
FROM FinalResults fr
WHERE 
    fr.TotalCommentScore > 10 
    OR (fr.TotalBountyAmount > 0 AND fr.ScoreCategory <> 'No Score')
ORDER BY fr.CreationDate DESC
LIMIT 100;