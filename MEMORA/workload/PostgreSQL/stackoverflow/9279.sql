WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.PostTypeId IN (1, 2)  
),
TopBadges AS (
    SELECT 
        B.UserId,
        B.Name AS BadgeName,
        COUNT(B.Id) AS BadgeCount,
        RANK() OVER (PARTITION BY B.UserId ORDER BY COUNT(B.Id) DESC) AS BadgeRank
    FROM 
        Badges B
    GROUP BY 
        B.UserId, B.Name
),
ActiveComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY C.PostId ORDER BY COUNT(C.Id) DESC) AS CommentRank
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    PP.Title AS PopularPost,
    PP.ViewCount,
    AB.BadgeName,
    AB.BadgeCount,
    COALESCE(AC.CommentCount, 0) AS ActiveComments
FROM 
    TopUsers TU
JOIN 
    PopularPosts PP ON PP.OwnerDisplayName = TU.DisplayName
LEFT JOIN 
    TopBadges AB ON AB.UserId = TU.UserId AND AB.BadgeRank = 1
LEFT JOIN 
    ActiveComments AC ON AC.PostId = PP.PostId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, PP.ViewCount DESC;