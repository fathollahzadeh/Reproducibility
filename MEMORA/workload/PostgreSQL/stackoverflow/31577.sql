
WITH RecentUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopUsers AS (
    SELECT 
        RUA.UserId,
        RUA.DisplayName,
        RUA.Reputation,
        RUA.VoteCount,
        RUA.CommentCount,
        RUA.PostCount,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        UB.Badges,
        RANK() OVER (ORDER BY RUA.Reputation DESC) AS ReputationRank,
        RUA.ActivityRank
    FROM 
        RecentUserActivity RUA
    LEFT JOIN 
        UserBadges UB ON RUA.UserId = UB.UserId
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.VoteCount,
    T.CommentCount,
    T.PostCount,
    T.BadgeCount,
    T.Badges,
    CASE 
        WHEN T.ReputationRank <= 10 THEN 'Top Users'
        ELSE 'General Users'
    END AS UserCategory
FROM 
    TopUsers T
WHERE 
    T.ActivityRank = 1 
ORDER BY 
    T.Reputation DESC;
