
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
        MAX(PH.CreationDate) AS LastCloseDate,
        STRING_AGG(CASE WHEN PH.UserId IS NOT NULL THEN PH.UserDisplayName END, ', ') AS Closers
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY P.Id, P.Title
),
TopClosedPosts AS (
    SELECT 
        CP.PostId,
        CP.Title,
        CP.CloseVoteCount,
        CP.LastCloseDate,
        CP.Closers,
        ROW_NUMBER() OVER (ORDER BY CP.CloseVoteCount DESC, CP.LastCloseDate ASC) AS Rank
    FROM ClosedPosts CP
    WHERE CP.CloseVoteCount > 0
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        (P.ViewCount + COALESCE((SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId IN (8, 9)), 0)) AS EngagementScore,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
      AND P.Score IS NOT NULL
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.EngagementScore,
    PS.OwnerDisplayName,
    TCP.CloseVoteCount,
    TCP.LastCloseDate,
    TCP.Closers,
    UVC.VoteCount AS UserVoteCount,
    UVC.UpVoteCount,
    UVC.DownVoteCount
FROM PostStats PS
LEFT JOIN TopClosedPosts TCP ON PS.PostId = TCP.PostId
LEFT JOIN UserVoteCounts UVC ON PS.OwnerDisplayName = UVC.DisplayName
WHERE PS.EngagementScore >= (SELECT AVG(EngagementScore) FROM PostStats)
  AND TCP.Rank <= 10
ORDER BY PS.EngagementScore DESC, PS.CreationDate ASC;
