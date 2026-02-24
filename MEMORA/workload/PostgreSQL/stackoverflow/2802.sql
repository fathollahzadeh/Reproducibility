WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
),
TopUsers AS (
    SELECT 
        U.*,
        COALESCE(B.Count, 0) AS BadgeCount,
        CASE 
            WHEN U.PositivePosts > U.NegativePosts THEN 'Positive Contributor'
            WHEN U.NegativePosts > U.PositivePosts THEN 'Negative Contributor'
            ELSE 'Neutral Contributor'
        END AS ContributorType
    FROM 
        RankedUsers U
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS Count 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) B ON U.UserId = B.UserId
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.BadgeCount,
    T.ContributorType,
    CASE 
        WHEN T.AverageViewCount IS NULL THEN 'No Views'
        ELSE CONCAT('Average Views: ', ROUND(T.AverageViewCount))
    END AS ViewFeedback,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = T.UserId AND V.VoteTypeId = 2) AS UpvotesGiven,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = T.UserId AND V.VoteTypeId = 3) AS DownvotesGiven
FROM 
    TopUsers T
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.Reputation DESC;
