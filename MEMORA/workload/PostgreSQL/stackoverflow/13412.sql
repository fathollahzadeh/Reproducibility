WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(CASE WHEN PostTypeId = 1 THEN Score ELSE NULL END) AS AvgQuestionScore
    FROM 
        Posts
),

AcceptedAnswers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS AcceptedAnswerCount
    FROM 
        Posts
    WHERE 
        AcceptedAnswerId IS NOT NULL
    GROUP BY 
        OwnerUserId
)

SELECT 
    PS.TotalPosts,
    PS.AvgQuestionScore,
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    AA.AcceptedAnswerCount
FROM 
    PostStats PS
CROSS JOIN 
    Users U
JOIN 
    AcceptedAnswers AA ON U.Id = AA.OwnerUserId
ORDER BY 
    AA.AcceptedAnswerCount DESC
LIMIT 5;