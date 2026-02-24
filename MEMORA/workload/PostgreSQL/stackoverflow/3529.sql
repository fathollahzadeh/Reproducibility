
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName, U.Views
), AcceptedAnswers AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.AcceptedAnswerId) AS AcceptedCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        P.OwnerUserId
), PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.Score > 0
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.Views,
    UR.Upvotes,
    UR.Downvotes,
    COALESCE(AA.AcceptedCount, 0) AS TotalAcceptedAnswers,
    COALESCE(PP.Title, 'No Popular Posts') AS PopularPostTitle,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    CASE 
        WHEN UR.Reputation >= 1000 THEN 'Veteran'
        WHEN UR.Reputation >= 500 THEN 'Experienced'
        ELSE 'Newbie'
    END AS UserLevel
FROM 
    UserReputation UR
LEFT JOIN 
    AcceptedAnswers AA ON UR.UserId = AA.OwnerUserId
LEFT JOIN 
    PopularPosts PP ON UR.UserId = PP.OwnerUserId AND PP.Rank = 1
LEFT JOIN 
    UserBadges UB ON UR.UserId = UB.UserId
ORDER BY 
    UR.Reputation DESC, UR.Views DESC
LIMIT 50;
