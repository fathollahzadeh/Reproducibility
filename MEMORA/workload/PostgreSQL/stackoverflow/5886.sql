WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName
    FROM RankedPosts rp
    WHERE rp.TagRank <= 5
),
PostStatistics AS (
    SELECT 
        tp.OwnerDisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        SUM(tp.ViewCount) AS TotalViews,
        AVG(tp.Score) AS AverageScore,
        SUM(tp.AnswerCount) AS TotalAnswers,
        SUM(tp.CommentCount) AS TotalComments
    FROM TopPosts tp
    GROUP BY tp.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    ps.TotalAnswers,
    ps.TotalComments,
    COALESCE(b.Name, 'No Badge') AS RecentBadge,
    Rank() OVER (ORDER BY ps.TotalViews DESC) AS ViewRank
FROM PostStatistics ps
LEFT JOIN (
    SELECT 
        UserId, 
        Name, 
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY Date DESC) AS RecentBadgeRank
    FROM Badges
) b ON ps.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId) AND b.RecentBadgeRank = 1
ORDER BY ps.TotalViews DESC, ps.OwnerDisplayName;