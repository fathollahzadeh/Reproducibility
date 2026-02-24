
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        Users.CreationDate,
        Users.LastAccessDate,
        Users.UpVotes,
        Users.DownVotes,
        (Users.UpVotes - Users.DownVotes) AS NetVotes,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 1 THEN Posts.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 2 THEN Posts.Id END) AS TotalAnswers,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName, Users.Reputation, Users.CreationDate, Users.LastAccessDate, Users.UpVotes, Users.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        NetVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    NetVotes,
    ReputationRank,
    PostRank,
    ViewRank
FROM TopUsers
WHERE TotalPosts > 0
ORDER BY Reputation DESC, TotalPosts DESC, TotalViews DESC
LIMIT 10;
