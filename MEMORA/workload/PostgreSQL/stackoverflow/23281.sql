
WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        CASE 
            WHEN U.Reputation >= 10000 THEN 'Elite'
            WHEN U.Reputation >= 1000 THEN 'Experienced'
            ELSE 'Novice'
        END AS UserTier
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' 
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstEditDate,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(DISTINCT PT.Name, ', ') AS EditTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    GROUP BY PH.PostId
),
FinalMetrics AS (
    SELECT 
        R.DisplayName,
        R.Reputation,
        R.UserTier,
        RP.Title,
        RP.CreationDate AS PostCreationDate,
        PH.FirstEditDate,
        PH.EditCount,
        RP.CommentCount,
        RP.UpVotes,
        RP.DownVotes,
        CASE 
            WHEN RP.AnswerId <> 0 THEN 'Yes'
            ELSE 'No'
        END AS HasAcceptedAnswer
    FROM RankedUsers R
    JOIN RecentPosts RP ON R.Id = RP.OwnerUserId
    LEFT JOIN PostHistoryInfo PH ON RP.PostId = PH.PostId
)
SELECT 
    *,
    (UpVotes - DownVotes) AS NetVotes,
    LEAD(PostCreationDate) OVER (PARTITION BY HasAcceptedAnswer ORDER BY PostCreationDate) AS NextPostCreationDate
FROM FinalMetrics
WHERE UserTier IN ('Elite', 'Experienced')
ORDER BY NetVotes DESC, PostCreationDate DESC
LIMIT 100;
