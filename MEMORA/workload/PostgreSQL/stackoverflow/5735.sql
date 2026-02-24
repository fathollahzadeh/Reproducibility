WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
), HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS RN
    FROM UserStats
    WHERE Reputation > 5000
), TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    T.TagName,
    T.PostsWithTag,
    T.TotalViews,
    T.AverageScore
FROM HighReputationUsers U
JOIN TagStats T ON U.TotalPosts > 10
WHERE U.RN <= 10
ORDER BY U.Reputation DESC, T.AverageScore DESC;
