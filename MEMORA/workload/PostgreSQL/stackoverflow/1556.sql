
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
ClosedPostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS ClosedPostsCount
    FROM 
        Posts P
    WHERE 
        P.ClosedDate IS NOT NULL
    GROUP BY 
        P.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS HistoryEventCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryEventTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.UpVotes,
    US.DownVotes,
    US.TotalPosts,
    COALESCE(CPS.ClosedPostsCount, 0) AS ClosedPostsCount,
    COALESCE(PHS.HistoryEventCount, 0) AS HistoryEventCount,
    COALESCE(PHS.HistoryEventTypes, 'None') AS HistoryEventTypes,
    US.ReputationRank
FROM 
    UserStats US
LEFT JOIN 
    ClosedPostStats CPS ON US.UserId = CPS.OwnerUserId
LEFT JOIN 
    PostHistoryStats PHS ON US.UserId = PHS.UserId
ORDER BY 
    US.Reputation DESC, US.TotalPosts DESC
LIMIT 100;
