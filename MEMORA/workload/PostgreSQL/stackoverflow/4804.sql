WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CloseReasonSummary AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseCount,
        STRING_AGG(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment ELSE 'No comment' END, ', ') AS CloseComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
CommentSummary AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeCommentsCount
    FROM 
        Comments c
    GROUP BY 
        c.UserId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    COALESCE(ps.QuestionsCount, 0) AS QuestionsCount,
    COALESCE(ps.AnswersCount, 0) AS AnswersCount,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    COALESCE(cr.CloseCount, 0) AS CloseCount,
    COALESCE(cr.CloseComments, 'No closures') AS CloseComments,
    COALESCE(cs.CommentsCount, 0) AS TotalComments,
    COALESCE(cs.NegativeCommentsCount, 0) AS NegativeComments
FROM 
    UserReputation ur
LEFT JOIN 
    PostStats ps ON ur.UserId = ps.OwnerUserId
LEFT JOIN 
    CloseReasonSummary cr ON ur.UserId = cr.UserId
LEFT JOIN 
    CommentSummary cs ON ur.UserId = cs.UserId
WHERE 
    ur.ReputationRank <= 100
ORDER BY 
    ur.Reputation DESC, 
    ur.DisplayName ASC;
