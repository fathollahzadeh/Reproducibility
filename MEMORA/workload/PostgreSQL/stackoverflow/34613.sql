WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(P.Score) AS MaxScore,
        MIN(P.Score) AS MinScore
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
PostHistoryGrouped AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM PostHistory PH
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        PT.Name AS PostType,
        PHG.ChangeCount AS EditCount
    FROM Posts P
    JOIN PostHistoryGrouped PHG ON P.Id = PHG.PostId
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UI.Rank, 0) AS UserRank,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.PostType,
    COALESCE(VS.VoteCount, 0) AS TotalVotes,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN PHG.ChangeCount IS NULL THEN 'No Changes'
        ELSE CONCAT(PHG.ChangeCount, ' edits')
    END AS EditStatus
FROM Users U
LEFT JOIN UserReputationCTE UI ON U.Id = UI.Id
LEFT JOIN RecentPosts RP ON U.Id = RP.Id
LEFT JOIN PostVoteSummary VS ON RP.Id = VS.PostId
LEFT JOIN PostHistoryGrouped PHG ON RP.Id = PHG.PostId
WHERE U.Reputation >= 100 AND RP.Score > 0
ORDER BY U.Reputation DESC, RP.ViewCount DESC;