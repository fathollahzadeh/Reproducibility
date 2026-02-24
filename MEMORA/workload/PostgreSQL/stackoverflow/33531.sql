
WITH RECURSIVE UserVotes AS (
    SELECT UserId, COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UV.TotalVotes
    FROM Users U
    JOIN UserVotes UV ON U.Id = UV.UserId
    WHERE U.Reputation > 1000
    ORDER BY UV.TotalVotes DESC
    LIMIT 10
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PH.PostHistoryCount, 0) AS PostHistoryCount,
        CASE
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS HasAcceptedAnswer
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS PostHistoryCount
        FROM PostHistory
        GROUP BY PostId
    ) PH ON P.Id = PH.PostId
),
UserPostInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        D.PostId,
        D.Title,
        D.CreationDate,
        D.Score,
        CASE WHEN V.VoteTypeId = 2 THEN 'Upvote' ELSE 'Downvote' END AS VoteType,
        D.HasAcceptedAnswer
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN PostDetails D ON P.Id = D.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
)

SELECT 
    U.DisplayName AS VotingUser,
    D.Title AS PostTitle,
    D.HasAcceptedAnswer,
    COUNT(*) AS VoteCount,
    AVG(D.Score) AS AvgScore,
    MAX(D.CreationDate) AS LatestPostDate
FROM UserPostInteractions D
JOIN TopUsers U ON D.UserId = U.Id
GROUP BY U.DisplayName, D.Title, D.HasAcceptedAnswer
HAVING COUNT(*) > 2
ORDER BY AvgScore DESC, VotingUser;
