WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 0
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostActivity AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM PostHistory PH
    WHERE PH.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
    GROUP BY PH.UserId, PH.PostId, PH.CreationDate, PH.PostHistoryTypeId
),
Result AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalPosts,
        US.Questions,
        US.Answers,
        US.AcceptedAnswers,
        US.TotalBadges,
        PA.ChangeCount
    FROM UserStats US
    LEFT JOIN PostActivity PA ON US.UserId = PA.UserId
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    AcceptedAnswers,
    TotalBadges,
    SUM(ChangeCount) AS TotalPostChanges
FROM Result
GROUP BY 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    AcceptedAnswers,
    TotalBadges
ORDER BY TotalPosts DESC, Reputation DESC
LIMIT 50;