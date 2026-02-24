WITH RECURSIVE UserBadges AS (
    
    SELECT 
        U.Id AS UserId,
        U.DisplayName, 
        B.Class, 
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, B.Class
),

RankedUsers AS (
    
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        RANK() OVER (PARTITION BY Class ORDER BY BadgeCount DESC) AS BadgeRank
    FROM UserBadges
),

PostStatistics AS (
    
    SELECT 
        P.Id AS PostId, 
        P.Title,
        COUNT(V.Id) AS TotalVotes,
        AVG(V.BountyAmount) AS AverageBountyAmount,
        SUM(COALESCE(V.BountyAmount, 0)) as TotalBounty,
        MAX(P.CreationDate) as LatestPostDate
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
),

CombinedStats AS (
    
    SELECT 
        RU.DisplayName,
        RU.BadgeCount,
        PS.PostId,
        PS.Title,
        PS.TotalVotes,
        PS.TotalBounty,
        PS.LatestPostDate
    FROM RankedUsers RU
    JOIN PostStatistics PS ON RU.BadgeRank = 1 
)


SELECT 
    CS.DisplayName,
    CS.BadgeCount,
    CS.PostId,
    CS.Title,
    CS.TotalVotes,
    CS.TotalBounty,
    CASE 
        WHEN CS.LatestPostDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivityStatus
FROM CombinedStats CS
ORDER BY CS.BadgeCount DESC, CS.TotalVotes DESC
LIMIT 10;