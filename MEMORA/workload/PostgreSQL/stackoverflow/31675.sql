
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id,
        P.ParentId,
        P.Title,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id,
        P.ParentId,
        P.Title,
        PH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy PH ON PH.Id = P.ParentId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
AggregatedPostData AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(PH.Level, 0) AS PostLevel,
        PS.UpVotes,
        PS.DownVotes,
        PS.TotalVotes,
        UBadges.BadgeCount,
        UBadges.Badges
    FROM 
        Posts P
    LEFT JOIN 
        PostHierarchy PH ON PH.Id = P.Id
    LEFT JOIN 
        PostVoteStats PS ON PS.PostId = P.Id
    LEFT JOIN 
        UserBadges UBadges ON UBadges.UserId = P.OwnerUserId
)
SELECT 
    APD.Id,
    APD.Title,
    APD.PostLevel,
    APD.UpVotes,
    APD.DownVotes,
    APD.TotalVotes,
    CASE 
        WHEN APD.BadgeCount IS NOT NULL THEN 
            CONCAT(APD.BadgeCount, ' badges: ', APD.Badges)
        ELSE 
            'No badges'
    END AS UserBadgeInfo
FROM 
    AggregatedPostData APD
ORDER BY 
    APD.PostLevel, APD.UpVotes DESC;
