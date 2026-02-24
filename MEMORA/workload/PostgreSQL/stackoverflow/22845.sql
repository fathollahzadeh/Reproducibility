
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswer,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosureCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId, P.OwnerUserId
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS UserRank
    FROM UserVoteCounts
    WHERE TotalVotes > 0
)

SELECT 
    U.DisplayName AS TopUser,
    P.Title AS TopPostTitle,
    P.CreationDate AS PostDate,
    P.Score AS PostScore,
    P.CommentCount,
    TU.UpVotes,
    TU.DownVotes,
    CASE 
        WHEN P.ClosureCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    P.UserPostRank
FROM PostActivity P
JOIN Users U ON P.AcceptedAnswer = U.Id
JOIN TopUsers TU ON TU.UserId = U.Id
WHERE TU.UserRank <= 5 
  AND P.Score > 0 
  AND P.UserPostRank = 1 
ORDER BY TU.UserRank, P.CreationDate DESC;
