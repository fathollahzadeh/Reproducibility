WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(A.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(Q.QuestionCount), 0) AS TotalQuestions,
        COALESCE(SUM(C.CommentCount), 0) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(A.AnswerCount), 0) DESC) AS AnswerRank
    FROM Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(Id) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY OwnerUserId
    ) A ON U.Id = A.OwnerUserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(Id) AS QuestionCount
        FROM Posts
        WHERE PostTypeId = 1
        GROUP BY OwnerUserId
    ) Q ON U.Id = Q.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY UserId
    ) C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName
),
HighActivityUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalAnswers,
        TotalQuestions,
        TotalComments,
        AnswerRank
    FROM UserActivity
    WHERE TotalAnswers > 10 OR TotalQuestions > 10
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS RecentPostCount
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.TotalAnswers,
    U.TotalQuestions,
    U.TotalComments,
    COALESCE(RP.RecentPostCount, 0) AS RecentPosts
FROM HighActivityUsers U
LEFT JOIN RecentPosts RP ON U.UserId = RP.OwnerUserId
ORDER BY U.TotalAnswers DESC, U.TotalQuestions DESC
LIMIT 100;