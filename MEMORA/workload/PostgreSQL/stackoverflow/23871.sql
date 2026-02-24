
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 'Unknown Reputation'
            WHEN U.Reputation < 1000 THEN 'Novice'
            WHEN U.Reputation BETWEEN 1000 AND 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 4 THEN 1 END) AS TotalOffensiveVotes,
        AVG(P.Score) OVER (PARTITION BY P.PostTypeId) AS AvgScorePerType
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id, P.OwnerUserId
),
BadgesEarned AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgesCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostAge AS (
    SELECT 
        P.Id AS PostId,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - P.CreationDate)) / 3600 AS AgeInHours
    FROM 
        Posts P
)
SELECT
    U.DisplayName,
    U.Reputation,
    UR.ReputationCategory,
    COALESCE(B.BadgesCount, 0) AS TotalBadges,
    COALESCE(B.BadgeNames, 'No Badges') AS BadgeNames,
    PS.TotalComments,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.TotalOffensiveVotes,
    PS.AvgScorePerType,
    PA.AgeInHours,
    CASE 
        WHEN PA.AgeInHours < 1 THEN 'Freshly Created'
        WHEN PA.AgeInHours BETWEEN 1 AND 24 THEN 'Recently Active'
        ELSE 'Old News'
    END AS PostAgeCategory
FROM 
    UserReputation UR
LEFT JOIN 
    Users U ON U.Id = UR.UserId
LEFT JOIN 
    PostStatistics PS ON PS.OwnerUserId = U.Id
LEFT JOIN 
    BadgesEarned B ON B.UserId = U.Id
LEFT JOIN 
    PostAge PA ON PA.PostId = PS.PostId
WHERE 
    U.Reputation > 500 
    AND (PS.TotalComments > 0 OR PS.TotalUpVotes > 5)
ORDER BY 
    U.Reputation DESC, PS.TotalUpVotes DESC;
