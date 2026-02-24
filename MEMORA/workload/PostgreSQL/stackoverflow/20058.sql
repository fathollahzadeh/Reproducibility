
WITH UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users U
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastEditOrCreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COALESCE(MAX(PH.CreationDate), P.CreationDate) DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    LEFT JOIN PostHistory PH ON PH.PostId = P.Id
    GROUP BY P.Id, P.PostTypeId, P.OwnerUserId
),
UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score <= 0 THEN 1 ELSE 0 END) AS NeutralOrNegativePosts
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id
),
FinalResults AS (
    SELECT 
        UReputation.UserId,
        UReputation.Reputation,
        UReputation.ReputationCategory,
        PA.PostId,
        PA.PostTypeId,
        PA.TotalComments,
        PA.UpVotes,
        PA.DownVotes,
        PA.LastEditOrCreationDate,
        UPC.PostCount,
        UPC.PositivePosts,
        UPC.NeutralOrNegativePosts,
        ROW_NUMBER() OVER (PARTITION BY UReputation.ReputationCategory ORDER BY PA.UpVotes - PA.DownVotes DESC) AS PopularityRank
    FROM UserReputations UReputation
    LEFT JOIN PostAnalytics PA ON PA.OwnerUserId = UReputation.UserId
    LEFT JOIN UserPostCounts UPC ON UPC.UserId = UReputation.UserId
)

SELECT 
    f.UserId,
    f.Reputation,
    f.ReputationCategory,
    f.PostId,
    f.PostTypeId,
    f.TotalComments,
    f.UpVotes,
    f.DownVotes,
    CASE 
        WHEN f.LastEditOrCreationDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days') THEN 'Old Activity'
        ELSE 'Recent Activity'
    END AS ActivityStatus,
    f.PostCount,
    f.PositivePosts,
    f.NeutralOrNegativePosts,
    f.PopularityRank
FROM FinalResults f
WHERE f.PopularityRank <= 10 
ORDER BY f.Reputation DESC, f.UpVotes - f.DownVotes DESC;
