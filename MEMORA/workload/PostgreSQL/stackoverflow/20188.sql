WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes
    FROM Users AS U
    LEFT JOIN Votes AS V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.ParentId,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) as PostRank
    FROM Posts AS P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoting AS (
    SELECT
        PS.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM PostSummary AS PS
    LEFT JOIN Votes AS V ON PS.PostId = V.PostId
    GROUP BY PS.PostId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory AS PH
    WHERE PH.PostHistoryTypeId = 10 
    GROUP BY PH.PostId
),
Ranking AS (
    SELECT 
        PS.PostId,
        SUM(COALESCE(PV.TotalUpVotes, 0)) AS FinalUpVotes,
        SUM(COALESCE(PV.TotalDownVotes, 0)) AS FinalDownVotes,
        SUM(COALESCE(CP.CloseCount, 0)) AS TotalCloseCount,
        PS.Title,
        PS.ViewCount,
        PS.OwnerUserId
    FROM PostSummary AS PS
    LEFT JOIN PostVoting AS PV ON PS.PostId = PV.PostId
    LEFT JOIN ClosedPosts AS CP ON PS.PostId = CP.PostId
    GROUP BY PS.PostId, PS.Title, PS.ViewCount, PS.OwnerUserId
)
SELECT 
    U.DisplayName,
    R.Title,
    R.FinalUpVotes,
    R.FinalDownVotes,
    R.TotalCloseCount
FROM Ranking AS R
JOIN Users AS U ON R.OwnerUserId = U.Id
WHERE R.TotalCloseCount > 0
ORDER BY 
    R.TotalCloseCount DESC,
    R.FinalUpVotes - R.FinalDownVotes DESC
LIMIT 10;