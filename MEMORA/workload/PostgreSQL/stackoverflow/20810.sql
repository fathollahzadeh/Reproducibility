
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY U.Id), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY U.Id), 0) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation IS NOT NULL
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT P.Tags) AS TotalTagsUsed
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
QualifiedUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        PS.TotalPosts,
        PS.TotalViews,
        PS.AverageScore,
        PS.TotalTagsUsed
    FROM 
        UserReputation UR
    LEFT JOIN 
        UserBadges UB ON UR.UserId = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON UR.UserId = PS.OwnerUserId
    WHERE 
        UR.Reputation > (
            SELECT 
                AVG(Reputation) 
            FROM 
                Users
        )
)
SELECT 
    QU.UserId,
    QU.DisplayName,
    QU.Reputation,
    QU.BadgeCount,
    QU.TotalPosts,
    QU.TotalViews,
    QU.AverageScore,
    QU.TotalTagsUsed,
    ROW_NUMBER() OVER (ORDER BY QU.Reputation DESC) AS Rank
FROM 
    QualifiedUsers QU
WHERE 
    (QU.BadgeCount > 5 OR QU.TotalPosts > 50)
    AND (QU.TotalViews IS NOT NULL)
ORDER BY 
    QU.Reputation DESC, QU.DisplayName ASC
FETCH FIRST 10 ROWS ONLY;
