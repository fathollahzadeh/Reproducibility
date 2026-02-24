WITH UserScoreRanks AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
), 
UserPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.ReputationRank,
    PP.Title AS MostPopularPostTitle,
    PP.Score AS MostPopularPostScore,
    PPC.PostCount
FROM 
    UserScoreRanks U
LEFT JOIN 
    PopularPosts PP ON PP.PopularityRank = 1 
LEFT JOIN 
    UserPostCounts PPC ON U.UserId = PPC.OwnerUserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, U.BadgeCount DESC;