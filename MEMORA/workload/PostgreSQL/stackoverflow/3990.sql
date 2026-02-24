WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT OUTER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT OUTER JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    U.TotalPosts,
    U.TotalComments
FROM 
    TopUsers U
LEFT JOIN 
    UserBadges UB ON U.UserId = UB.UserId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC
LIMIT 10;