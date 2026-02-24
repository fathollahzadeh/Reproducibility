
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostVoteSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2) 
    GROUP BY 
        OwnerUserId
),
UserStatistics AS (
    SELECT 
        RU.UserId,
        RU.DisplayName,
        COALESCE(PCS.PostCount, 0) AS TotalPosts,
        COALESCE(VS.VoteCount, 0) AS TotalVotes,
        COALESCE(VS.UpVotes, 0) AS UpVotes,
        COALESCE(VS.DownVotes, 0) AS DownVotes,
        RU.ReputationRank
    FROM 
        RankedUsers RU
    LEFT JOIN 
        PostCounts PCS ON RU.UserId = PCS.OwnerUserId
    LEFT JOIN 
        PostVoteSummary VS ON RU.UserId = VS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    CASE 
        WHEN U.TotalVotes > 0 THEN ROUND((U.UpVotes::decimal / U.TotalVotes) * 100, 2) 
        ELSE NULL 
    END AS UpvotePercentage,
    CASE 
        WHEN U.ReputationRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    UserStatistics U
JOIN 
    RankedUsers RU ON U.UserId = RU.UserId
ORDER BY 
    U.TotalPosts DESC, U.UpVotes DESC;
