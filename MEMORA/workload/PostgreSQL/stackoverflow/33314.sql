WITH RECURSIVE UserAnswerCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS AnswerCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 2  
    GROUP BY 
        U.Id
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        V.UserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostsWithDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(U.AnswerCount, 0) AS AnswerCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount,
        COALESCE(UB.BadgeNames, 'No Badges') AS BadgeNames
    FROM 
        Posts P
    LEFT JOIN 
        UserAnswerCounts U ON P.OwnerUserId = U.UserId
    LEFT JOIN 
        RecentVotes RV ON P.OwnerUserId = RV.UserId
    LEFT JOIN 
        UserBadges UB ON P.OwnerUserId = UB.UserId
    WHERE 
        P.PostTypeId = 1  
)

SELECT 
    PWD.PostId,
    PWD.Title,
    PWD.CreationDate,
    PWD.ViewCount,
    PWD.AnswerCount,
    PWD.RecentVoteCount,
    PWD.BadgeNames,
    CASE 
        WHEN PWD.ViewCount > 1000 THEN 'High'
        WHEN PWD.ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ViewCategory
FROM 
    PostsWithDetails PWD
ORDER BY 
    PWD.ViewCount DESC
LIMIT 10;