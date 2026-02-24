
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(AVG(P.ViewCount), 0) AS AverageViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
EncouragedUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        AverageViews,
        TotalPosts,
        TotalUpvotes,
        TotalDownvotes,
        UserRank,
        CASE 
            WHEN TotalUpvotes > TotalDownvotes THEN 'Encouraged'
            ELSE 'Discouraged'
        END AS Sentiment
    FROM UserStats
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
),
PopularPosts AS (
    SELECT 
        P.OwnerUserId, 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY P.OwnerUserId, P.Id, P.Title
)
SELECT 
    EU.UserId, 
    EU.DisplayName, 
    EU.Reputation,
    EU.TotalPosts,
    EU.TotalUpvotes,
    EU.TotalDownvotes,
    UB.BadgeNames,
    PP.PostId,
    PP.Title AS PopularPostTitle,
    PP.CommentCount,
    EU.Sentiment
FROM EncouragedUsers EU
LEFT JOIN UserBadges UB ON EU.UserId = UB.UserId
LEFT JOIN PopularPosts PP ON EU.UserId = PP.OwnerUserId AND PP.PostRank = 1
WHERE 
    EXISTS (
        SELECT 1 
        FROM EncouragedUsers 
        WHERE Sentiment = 'Encouraged' 
          AND UserId = EU.UserId
    )
    AND EU.Reputation > (
        SELECT AVG(Reputation) 
        FROM Users 
        WHERE Reputation IS NOT NULL
    )
ORDER BY EU.UserRank, EU.TotalUpvotes DESC;
