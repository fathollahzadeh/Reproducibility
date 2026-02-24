WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
CommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        cs.CommentCount,
        cs.AvgCommentScore,
        CASE 
            WHEN cs.AvgCommentScore IS NULL THEN 'No Comments'
            WHEN cs.AvgCommentScore > 2 THEN 'Highly Engaged'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentStats cs ON tp.Id = cs.PostId
)
SELECT 
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.CommentCount,
    fr.AvgCommentScore,
    fr.EngagementLevel
FROM 
    FinalResults fr
WHERE 
    fr.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;