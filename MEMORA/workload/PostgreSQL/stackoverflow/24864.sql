WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id, U.Reputation
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(UPV.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DNV.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount 
         FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) UPV ON P.Id = UPV.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVoteCount 
         FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId) DNV ON P.Id = DNV.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        P.Title, 
        PH.Comment AS CloseReason,
        PH.CreationDate AS ClosedOn,
        RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS CloseRank
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    U.UserId, 
    U.Reputation, 
    U.PostCount,
    (U.UpVotes - U.DownVotes) AS VoteBalance,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.ViewCount,
    PS.RecentPostRank,
    CP.Title AS ClosedPostTitle,
    CP.CloseReason AS CloseReasonDetails,
    CP.ClosedOn AS ClosedDate
FROM 
    UserActivity U
LEFT JOIN 
    PostStats PS ON U.UserId = PS.PostId 
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.ClosedPostId
WHERE 
    U.ReputationRank <= 10
    AND (U.UpVotes > 5 OR U.DownVotes < 3)
ORDER BY 
    U.Reputation DESC, 
    PS.RecentPostRank
LIMIT 100;