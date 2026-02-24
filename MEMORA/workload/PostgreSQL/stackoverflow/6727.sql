
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN BH.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges BH ON U.Id = BH.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
UserPerformance AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes - Downvotes AS VoteBalance,
        PostCount,
        BadgeCount,
        RANK() OVER (ORDER BY (Upvotes - Downvotes) DESC, PostCount DESC, Reputation DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    U.UserRank,
    U.DisplayName,
    U.Reputation,
    U.VoteBalance,
    U.PostCount,
    U.BadgeCount,
    CASE 
        WHEN U.VoteBalance > 100 THEN 'Outstanding'
        WHEN U.VoteBalance BETWEEN 50 AND 100 THEN 'Good'
        WHEN U.VoteBalance BETWEEN 0 AND 49 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS PerformanceCategory
FROM 
    UserPerformance U
WHERE 
    U.PostCount > 0
ORDER BY 
    U.UserRank
FETCH FIRST 10 ROWS ONLY;
