
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(A.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.AcceptedAnswerId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, A.AcceptedAnswerId
), 
MostVotedPosts AS (
    SELECT 
        PS.*, 
        UR.DisplayName AS OwnerDisplayName
    FROM PostStats PS
    JOIN Users U ON PS.PostId = U.Id
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    WHERE PS.VoteCount > 0
), 
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS ClosureCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.PostId
)
SELECT 
    MVP.PostId, 
    MVP.Title, 
    MVP.ViewCount,
    MVP.CommentCount,
    MVP.UpVotes,
    MVP.DownVotes,
    COALESCE(CP.ClosureCount, 0) AS ClosureCount,
    MVP.OwnerDisplayName,
    CASE 
        WHEN MVP.AcceptedAnswerId = -1 THEN 'Not Accepted'
        ELSE 'Accepted'
    END AS AnswerStatus
FROM MostVotedPosts MVP
LEFT JOIN ClosedPosts CP ON MVP.PostId = CP.PostId
ORDER BY MVP.UpVotes DESC, MVP.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
