
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes_Count,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes_Count,
        COUNT(DISTINCT P.Id) AS Posts_Count,
        COUNT(DISTINCT C.Id) AS Comments_Count
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 12, 11) 
),
RankingUsers AS (
    SELECT 
        UserId,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.UpVotes_Count,
    U.DownVotes_Count,
    U.Posts_Count,
    U.Comments_Count,
    PH.Comment AS PostHistoryComment,
    P.Title AS PostTitle,
    PH.CreationDate AS HistoryDate,
    R.UserRank
FROM 
    UserStatistics U
LEFT JOIN 
    PostHistoryDetails PH ON U.UserId = PH.UserId
JOIN 
    Posts P ON PH.PostId = P.Id
JOIN 
    RankingUsers R ON U.UserId = R.UserId
WHERE 
    U.Reputation > 1000
    AND PH.RecentHistory = 1
ORDER BY 
    U.Reputation DESC, 
    PH.CreationDate DESC;
