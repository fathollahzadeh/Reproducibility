WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND P.PostTypeId = 1 
),
VoteSummary AS (
    SELECT 
        PV.PostId,
        COUNT(CASE WHEN PV.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN PV.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes PV
    GROUP BY 
        PV.PostId
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS ChangeType
    FROM 
        PostHistory PH
)
SELECT 
    RU.DisplayName AS TopContributor,
    RU.Reputation AS ContributorReputation,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
    PH.ChangeType AS PostChangeType,
    PH.CreationDate AS ChangeDate
FROM 
    RankedUsers RU
LEFT JOIN 
    RecentPosts RP ON RU.UserId = RP.OwnerUserId
LEFT JOIN 
    VoteSummary VS ON RP.PostId = VS.PostId
LEFT JOIN 
    PostHistoryInfo PH ON RP.PostId = PH.PostId AND PH.HistoryRank = 1
WHERE 
    RU.ReputationRank <= 10
    AND (RP.RecentRank = 1 OR RP.RecentRank IS NULL)
ORDER BY 
    RU.Reputation DESC, RP.CreationDate DESC;