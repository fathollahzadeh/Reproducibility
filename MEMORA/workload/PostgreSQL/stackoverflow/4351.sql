
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),

TopPosts AS (
    SELECT 
        rp.*,
        u.Reputation AS OwnerReputation,
        CASE 
            WHEN b.Id IS NOT NULL THEN 'Badged'
            ELSE 'Not Badged'
        END AS BadgeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id AND b.Class = 1 
    WHERE 
        rp.PostRank <= 5
),

PostAggregates AS (
    SELECT 
        tp.OwnerUserId,
        SUM(tp.Score) AS TotalScore,
        AVG(tp.ViewCount) AS AvgViewCount,
        COUNT(*) AS PostCount,
        MAX(tp.AnswerCount) AS MaxAnswerCount,
        MIN(tp.CommentCount) AS MinCommentCount
    FROM 
        TopPosts tp
    GROUP BY 
        tp.OwnerUserId
)

SELECT 
    u.DisplayName,
    pa.TotalScore,
    pa.AvgViewCount,
    pa.PostCount,
    pa.MaxAnswerCount,
    pa.MinCommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeType
FROM 
    PostAggregates pa
JOIN 
    Users u ON u.Id = pa.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Class = 2 
ORDER BY 
    pa.TotalScore DESC
LIMIT 10
