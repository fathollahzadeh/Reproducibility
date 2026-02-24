WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS Rnk
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 500
    GROUP BY u.Id, u.Reputation
),
Questions AS (
    SELECT 
        pt.Name AS PostType,
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        COALESCE(ahs.AvgScore, 0) AS AverageScore,
        COALESCE(pv.SimilarQuestionsCount, 0) AS SimilarQuestionsCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            p1.ParentId,
            AVG(p1.Score) AS AvgScore
        FROM Posts p1
        WHERE p1.PostTypeId = 2  
        GROUP BY p1.ParentId
    ) ahs ON p.Id = ahs.ParentId
    LEFT JOIN (
        SELECT 
            pl.PostId,
            COUNT(*) AS SimilarQuestionsCount
        FROM PostLinks pl
        JOIN Posts p2 ON pl.RelatedPostId = p2.Id
        WHERE p2.PostTypeId = 1  
        GROUP BY pl.PostId
    ) pv ON p.Id = pv.PostId
    WHERE pt.Name = 'Question'
)
SELECT 
    u.DisplayName,
    ur.Reputation,
    ur.TotalBounty,
    ur.BadgeCount,
    q.PostType,
    q.QuestionId,
    q.Title,
    q.CreationDate,
    CASE 
        WHEN q.AverageScore IS NULL THEN 'No Score'
        WHEN q.AverageScore > 10 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS ScoreCategory,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Comments c
            WHERE c.PostId = q.QuestionId 
            AND c.Score < 0 
            AND c.CreationDate > q.CreationDate
        ) THEN 'Has Negative Comments'
        ELSE 'No Negative Comments'
    END AS CommentStatus,
    q.SimilarQuestionsCount
FROM UserReputation ur
JOIN Users u ON u.Id = ur.UserId
LEFT JOIN Questions q ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = q.QuestionId)
WHERE ur.Rnk <= 10
ORDER BY ur.Reputation DESC, q.SimilarQuestionsCount DESC;