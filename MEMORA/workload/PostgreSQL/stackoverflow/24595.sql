WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
QuestionsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rb.Class AS BadgeClass,
        rb.Name AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges rb ON rb.UserId = (
            SELECT 
                u.Id 
            FROM 
                Users u 
            WHERE 
                u.DisplayName = rp.OwnerDisplayName 
                AND u.Reputation > 1000 
                ORDER BY u.CreationDate ASC LIMIT 1
        )
    WHERE 
        rp.RecentPostRank = 1
),
PostStatistics AS (
    SELECT 
        q.Title,
        q.BadgeName,
        COALESCE(q.ViewCount, 0) AS ViewCount,
        COALESCE(q.Score, 0) AS Score,
        COALESCE(q.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN q.BadgeClass IS NOT NULL THEN 
                'User with Badge: ' || q.BadgeName 
            ELSE 
                'No Badge' 
        END AS BadgeStatus
    FROM 
        QuestionsWithBadges q
),
CommentSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.Title,
    ps.BadgeStatus,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    COALESCE(cs.CommentCount, 0) AS TotalComments,
    cs.LastCommentDate,
    CASE 
        WHEN ps.Score > 100 THEN 'Very Popular'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityStatus,
    CASE 
        WHEN cs.LastCommentDate IS NULL THEN 'No comments yet'
        WHEN cs.LastCommentDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Last comment over a year ago'
        ELSE 'Recent comments'
    END AS CommentActivityStatus
FROM 
    PostStatistics ps
LEFT JOIN 
    CommentSummary cs ON ps.Title = (
        SELECT 
            Title 
        FROM 
            Posts 
        WHERE 
            Id = cs.PostId
    )
WHERE 
    ps.ViewCount > 10 
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
OFFSET 10 ROWS 
FETCH NEXT 10 ROWS ONLY;