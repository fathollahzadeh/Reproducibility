
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        CTR.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        CloseReasonTypes CTR ON CAST(PH.Comment AS int) = CTR.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        UserId, 
        RANK() OVER (ORDER BY SUM(UpVotes) DESC) AS Rank
    FROM 
        UserVoteStats
    GROUP BY 
        UserId
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    COALESCE(COUNT(DISTINCT CP.PostId), 0) AS ClosedPostCount,
    COALESCE(STRING_AGG(CONCAT(CP.Title, ' (Closed on: ', CAST(CP.ClosedDate AS date), ' - Reason: ', CP.CloseReason, ')'), '; '), 'No closed posts') AS ClosedPostDetails
FROM 
    UserVoteStats U
LEFT JOIN 
    ClosedPosts CP ON U.UserId = CP.PostId
WHERE 
    U.UpVotes - U.DownVotes > 10
GROUP BY 
    U.DisplayName, U.UpVotes, U.DownVotes
ORDER BY 
    U.UpVotes DESC
LIMIT 10;
