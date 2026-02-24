
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate ASC) AS CreationRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '365 days')
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        COUNT(c.Id) FILTER (WHERE c.Score >= 0) AS PositiveComments,
        COUNT(DISTINCT v.UserId) AS UniqueUpvoters
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId = 2  
    WHERE 
        rp.RankScore <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.AnswerCount
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        tp.PositiveComments,
        tp.UniqueUpvoters,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)), 0) AS TotalBadgeClass,
        (SELECT COUNT(DISTINCT pl.RelatedPostId) FROM PostLinks pl WHERE pl.PostId = tp.PostId) AS RelatedPostCount
    FROM 
        TopPosts tp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.PositiveComments,
    pd.UniqueUpvoters,
    pd.TotalBadgeClass,
    pd.RelatedPostCount,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score'
        WHEN pd.Score > 10 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory,
    CASE 
        WHEN pd.ViewCount IS NULL THEN 'Unseen'
        WHEN pd.ViewCount > 1000 THEN 'Trending'
        ELSE 'Normal'
    END AS TrendStatus
FROM 
    PostDetails pd
WHERE 
    (pd.TotalBadgeClass > 10 OR pd.ViewCount > 500)
    AND pd.UniqueUpvoters > 2
ORDER BY 
    pd.Score DESC NULLS LAST, 
    pd.ViewCount DESC;
