WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
)


SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    SUM(P.ViewCount) AS TotalViews,
    SUM(P.AnswerCount) AS TotalAnswers,
    SUM(P.CommentCount) AS TotalComments,
    SUM(P.FavoriteCount) AS TotalFavorites,
    U.UserId,
    U.DisplayName,
    U.Reputation
FROM Posts P
JOIN PostTypes PT ON P.PostTypeId = PT.Id
JOIN UserStats U ON P.OwnerUserId = U.UserId
GROUP BY PT.Name, U.UserId, U.DisplayName, U.Reputation
ORDER BY TotalPosts DESC, AverageScore DESC;