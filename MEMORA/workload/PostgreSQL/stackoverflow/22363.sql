WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 'Unknown' 
            WHEN U.Reputation > 1000 THEN 'Gold'
            WHEN U.Reputation > 500 THEN 'Silver'
            ELSE 'Bronze'
        END AS ReputationTier
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentsCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
PostHistoryAggregated AS (
    SELECT 
        PH.PostId,
        ARRAY_AGG(DISTINCT PH.Comment) AS CloseComments,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) AND PH.Comment IS NOT NULL THEN 1 END) AS CloseOrReopenCount
    FROM PostHistory PH
    GROUP BY PH.PostId
),
FinalResults AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.Upvotes,
        PS.Downvotes,
        PH.CloseComments,
        PH.CloseOrReopenCount,
        UR.ReputationTier,
        CASE 
            WHEN PS.Upvotes = 0 AND PS.Downvotes = 0 THEN 'No Votes'
            ELSE CASE 
                WHEN PS.Upvotes > PS.Downvotes THEN 'Positive'
                WHEN PS.Downvotes > PS.Upvotes THEN 'Negative'
                ELSE 'Neutral'
            END
        END AS VotingSentiment,
        ROW_NUMBER() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.Upvotes DESC) AS PostRank
    FROM PostStatistics PS
    LEFT JOIN UserReputation UR ON PS.OwnerUserId = UR.UserId
    LEFT JOIN PostHistoryAggregated PH ON PS.PostId = PH.PostId
)
SELECT 
    FR.PostId,
    U.DisplayName,
    FR.Upvotes,
    FR.Downvotes,
    FR.CloseComments,
    FR.CloseOrReopenCount,
    FR.ReputationTier,
    FR.VotingSentiment,
    FR.PostRank
FROM FinalResults FR
JOIN Users U ON FR.OwnerUserId = U.Id
WHERE FR.ReputationTier IS NOT NULL AND FR.CloseOrReopenCount > 0
ORDER BY FR.ReputationTier DESC, FR.PostRank;
