
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT PH.Id) AS TotalHistoryChanges
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.UpVotes,
    US.DownVotes,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.ViewCount AS PostViewCount,
    PS.Score AS PostScore,
    PS.TotalComments AS PostTotalComments,
    PS.TotalHistoryChanges AS PostTotalHistoryChanges
FROM 
    UserStatistics US
JOIN 
    PostStatistics PS ON US.UserId = PS.PostId
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC;
