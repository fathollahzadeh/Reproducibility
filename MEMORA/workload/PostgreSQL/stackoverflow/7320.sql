WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AverageScore,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TimesClosed,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TimesReopened,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (52, 53) THEN 1 ELSE 0 END) AS HotQuestionChanges
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UVS.UpVotes,
        UVS.DownVotes,
        PS.TotalPosts AS UserTotalPosts,
        PS.AverageScore,
        PS.TimesClosed,
        PS.TimesReopened,
        PS.HotQuestionChanges
    FROM 
        UserVoteStats UVS
    JOIN 
        PostStatistics PS ON UVS.UserId = PS.OwnerUserId
    JOIN 
        Users U ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    UpVotes,
    DownVotes,
    UserTotalPosts,
    AverageScore,
    TimesClosed,
    TimesReopened,
    HotQuestionChanges
FROM 
    CombinedStats
WHERE 
    Reputation > 1000
ORDER BY 
    UpVotes DESC, AverageScore DESC
LIMIT 50;
