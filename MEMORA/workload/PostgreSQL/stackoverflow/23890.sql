WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(cmt.CommentCount, 0) AS CommentCount,
        COALESCE(b.UserId, -1) AS BadgeUserId,
        COALESCE(CASE WHEN p.PostTypeId = 1 THEN b.Name END, 'No Badge') AS UserBadge
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cmt ON p.Id = cmt.PostId
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
AggregatedData AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.Score,
        r.AnswerCount,
        r.CommentCount,
        r.ViewRank,
        r.ScoreRank,
        (CASE 
            WHEN r.ViewRank <= 5 THEN 'Top Views'
            WHEN r.ScoreRank <= 5 THEN 'Top Scores'
            ELSE 'Others' END) AS PostCategory
    FROM RankedPosts r
), 
CommentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        STRING_AGG(c.Text, '; ') AS SampleComments
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)
SELECT 
    a.PostId,
    a.Title,
    a.CreationDate,
    a.ViewCount,
    a.Score,
    a.AnswerCount,
    a.CommentCount,
    a.PostCategory,
    COALESCE(ca.TotalComments, 0) AS CountOfComments,
    COALESCE(ca.SampleComments, 'No comments yet') AS ExampleComments,
    CASE 
        WHEN a.PostCategory = 'Top Views' AND a.CommentCount > 0 THEN 'Popular & Engaged'
        WHEN a.PostCategory = 'Top Scores' AND a.CommentCount = 0 THEN 'Highly Rated but No Engagement'
        ELSE 'Standard Engagement' 
    END AS EngagementStatus
FROM AggregatedData a
LEFT JOIN CommentActivity ca ON a.PostId = ca.PostId
WHERE 
    a.ViewCount > 10 AND
    a.CommentCount IS NOT NULL
ORDER BY 
    a.CommentCount DESC, a.ViewCount DESC
LIMIT 50;