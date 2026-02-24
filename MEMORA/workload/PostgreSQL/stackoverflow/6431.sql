WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
AggregateStats AS (
    SELECT 
        r.OwnerDisplayName,
        COUNT(*) AS TotalPosts,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews,
        AVG(r.AnswerCount) AS AverageAnswers,
        AVG(r.CommentCount) AS AverageComments
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank <= 5 
    GROUP BY 
        r.OwnerDisplayName
)
SELECT 
    a.OwnerDisplayName,
    a.TotalPosts,
    a.TotalScore,
    a.TotalViews,
    a.AverageAnswers,
    a.AverageComments,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    AggregateStats a
LEFT JOIN (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
) b ON a.OwnerDisplayName = b.DisplayName
ORDER BY 
    a.TotalScore DESC, 
    a.TotalPosts DESC
LIMIT 10;