
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        H.CreationDate AS CloseDate,
        C.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory H ON P.Id = H.PostId AND H.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes C ON CAST(H.Comment AS INT) = C.Id
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.QuestionCount,
        (UA.UpVotes - UA.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY (UA.UpVotes - UA.DownVotes) DESC, UA.Reputation DESC) AS VoteRank
    FROM 
        UserActivity UA
    WHERE 
        UA.QuestionCount > 5
)
SELECT 
    TU.DisplayName, 
    TU.Reputation,
    TU.QuestionCount,
    TU.NetVotes,
    CP.Title AS ClosedPostTitle,
    CP.CloseDate,
    COALESCE(CP.CloseReason, 'No Reason Provided') AS CloseReason
FROM 
    TopUsers TU
LEFT JOIN 
    ClosedPosts CP ON TU.UserId = CP.PostId
WHERE 
    TU.VoteRank <= 10 OR CP.CloseReason IS NOT NULL
ORDER BY 
    TU.Reputation DESC, 
    TU.NetVotes DESC;
