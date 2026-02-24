
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.CreationDate,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON C.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.CreationDate, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        TotalComments,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation
    FROM 
        UserActivity
),
RecentActivity AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        GREATEST(P.LastActivityDate, COALESCE(C.CreationDate, '1900-01-01')::timestamp) AS MostRecentActivityDate
    FROM 
        TopUsers U
    LEFT JOIN 
        Posts P ON U.UserId = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.UserId = C.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    CASE 
        WHEN U.PostCount > 0 THEN (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.UserId AND V.VoteTypeId = 2) 
        ELSE 0 
    END AS UpVoteCount,
    A.MostRecentActivityDate,
    CASE 
        WHEN U.RankByReputation <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel
FROM 
    TopUsers U
JOIN 
    RecentActivity A ON U.UserId = A.UserId
WHERE 
    A.MostRecentActivityDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
ORDER BY 
    U.Reputation DESC, U.PostCount DESC;
