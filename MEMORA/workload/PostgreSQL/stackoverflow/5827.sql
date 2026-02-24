
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END), 0) AS TotalViewsOnQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN P.ViewCount ELSE 0 END), 0) AS TotalViewsOnAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionsAsked,
        AnswersProvided,
        TotalViewsOnQuestions,
        TotalViewsOnAnswers,
        TotalComments,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    QuestionsAsked,
    AnswersProvided,
    TotalViewsOnQuestions,
    TotalViewsOnAnswers,
    TotalComments,
    TotalBadges,
    ReputationRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10
ORDER BY 
    Reputation DESC;
