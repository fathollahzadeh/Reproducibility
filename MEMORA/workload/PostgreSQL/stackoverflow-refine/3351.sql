
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 1) THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBounty, 
        UpVotes, 
        DownVotes, 
        AvgScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
), RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.AnswerCount,
        P.ViewCount,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days' AND P.ViewCount > 0
)

SELECT 
    RU.DisplayName, 
    RU.Reputation, 
    RU.PostCount, 
    RU.TotalBounty, 
    RU.UpVotes, 
    RU.DownVotes, 
    RU.AvgScore, 
    RP.PostId,
    RP.Title AS RecentPostTitle, 
    RP.CreationDate AS RecentPostDate, 
    RP.ViewCount AS RecentPostViewCount
FROM 
    RankedUsers RU
LEFT JOIN 
    RecentPosts RP ON RU.UserId = RP.OwnerUserId
WHERE 
    RP.RecentPostRank = 1 OR RP.RecentPostRank IS NULL
ORDER BY 
    RU.ReputationRank;
