WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        COALESCE(RPC.PostCount, 0) AS RecentPostCount
    FROM UserReputation UR
    LEFT JOIN RecentPostCounts RPC ON UR.UserId = RPC.OwnerUserId
    WHERE UR.Reputation > 1000
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount, 
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount 
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        PD.Title,
        PD.Score, 
        PD.CommentCount,
        PD.UpVoteCount,
        PD.DownVoteCount,
        COALESCE(PH.UserDisplayName, 'Unknown User') AS LastEditBy,
        PD.PostId,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC) AS PopularityRank
    FROM PostDetails PD
    LEFT JOIN PostHistory PH ON PD.PostId = PH.PostId AND PH.CreationDate = (
        SELECT MAX(PH2.CreationDate) 
        FROM PostHistory PH2 
        WHERE PH2.PostId = PD.PostId
    )
    WHERE PD.Score > 0 
),
UserPostRankings AS (
    SELECT 
        TU.DisplayName,
        TU.Reputation,
        PS.Title,
        PS.Score,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount,
        PS.PopularityRank,
        CASE 
            WHEN PS.PopularityRank <= 10 THEN 'Top 10'
            WHEN PS.PopularityRank BETWEEN 11 and 50 THEN 'Top 11-50'
            ELSE 'Beyond Top 50'
        END AS PopularityCategory
    FROM TopUsers TU
    INNER JOIN PostSummary PS ON TU.DisplayName = PS.LastEditBy
)
SELECT 
    UPR.DisplayName,
    UPR.Reputation,
    UPR.Title,
    UPR.Score,
    UPR.CommentCount,
    UPR.UpVoteCount,
    UPR.DownVoteCount,
    UPR.PopularityRank,
    UPR.PopularityCategory,
    CASE 
        WHEN UPR.Reputation > 5000 THEN 'Platinum Contributor'
        WHEN UPR.Reputation BETWEEN 3000 AND 4999 THEN 'Gold Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorBadge
FROM UserPostRankings UPR
ORDER BY UPR.PopularityRank
FETCH FIRST 50 ROWS ONLY;