
WITH RECURSIVE UserPostHierarchy AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        1 AS Level
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        P.Id,
        P.Title,
        P.CreationDate,
        UPH.Level + 1
    FROM 
        UserPostHierarchy UPH
    JOIN 
        Posts P ON UPH.PostId = P.ParentId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, B.Class
)
SELECT 
    UPH.UserId,
    UPH.DisplayName,
    UPH.Title AS QuestionTitle,
    UPH.CreationDate AS QuestionDate,
    PS.Upvotes,
    PS.Downvotes,
    PS.TotalVotes,
    COALESCE(TotalBadges.BadgeCount, 0) AS BadgeCount,
    STRING_AGG(CASE WHEN UB.Class = 1 THEN 'Gold' 
                    WHEN UB.Class = 2 THEN 'Silver' 
                    ELSE 'Bronze' END, ', ') AS BadgeTypes,
    ROW_NUMBER() OVER (PARTITION BY UPH.UserId ORDER BY UPH.CreationDate DESC) AS Rank
FROM 
    UserPostHierarchy UPH
LEFT JOIN 
    VoteSummary PS ON UPH.PostId = PS.PostId
LEFT JOIN 
    UserBadges UB ON UPH.UserId = UB.UserId
LEFT JOIN 
    (SELECT UserId, SUM(BadgeCount) AS BadgeCount
     FROM UserBadges
     GROUP BY UserId) AS TotalBadges ON UPH.UserId = TotalBadges.UserId
GROUP BY 
    UPH.UserId, UPH.DisplayName, UPH.Title, UPH.CreationDate, PS.Upvotes, PS.Downvotes, PS.TotalVotes, TotalBadges.BadgeCount
HAVING 
    COUNT(UPH.PostId) > 1 
ORDER BY 
    BadgeCount DESC, UPH.CreationDate DESC;
