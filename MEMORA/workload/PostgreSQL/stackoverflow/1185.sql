WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswersCount,
        MAX(U.LastAccessDate) AS LastAccessed
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
TopContributors AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        UserStatistics U
    WHERE 
        U.Reputation > 1000
)
SELECT 
    UStats.UserId,
    UStats.DisplayName,
    UStats.Reputation,
    P.Title AS TopQuestionTitle,
    P.Score AS QuestionScore,
    P.ViewCount AS QuestionViews,
    P.CommentCount AS QuestionComments,
    P.TotalBounty AS QuestionBounty,
    T.Rank
FROM 
    UserStatistics UStats
INNER JOIN 
    PostAnalytics P ON UStats.UserId = (
        SELECT OwnerUserId
        FROM Posts
        WHERE PostTypeId = 1
        ORDER BY Score DESC
        LIMIT 1
    )
LEFT JOIN 
    TopContributors T ON UStats.DisplayName = T.DisplayName
WHERE 
    UStats.Reputation > 500
ORDER BY 
    UStats.Reputation DESC, QuestionViews DESC
LIMIT 10;