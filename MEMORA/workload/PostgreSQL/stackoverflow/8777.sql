WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(P.Score) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        UpVotesCount,
        DownVotesCount,
        TotalViews,
        TotalPosts,
        AveragePostScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY UpVotesCount DESC) AS UpVotesRank
    FROM 
        UserStats
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    UpVotesCount,
    DownVotesCount,
    TotalViews,
    TotalPosts,
    AveragePostScore,
    ReputationRank,
    UpVotesRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10 OR UpVotesRank <= 10
ORDER BY 
    ReputationRank, UpVotesRank;
