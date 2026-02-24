WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(V.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)

SELECT 
    U.DisplayName AS User,
    U.TotalPosts,
    U.TotalBounty,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    R.Title,
    R.CreationDate,
    R.Score,
    R.ViewCount,
    COALESCE(PC.CommentCount, 0) AS TotalComments
FROM 
    UserStats U
JOIN 
    RankedPosts R ON U.UserId = R.PostId
LEFT JOIN 
    PostComments PC ON R.PostId = PC.PostId
WHERE 
    R.rn = 1
ORDER BY 
    U.TotalBounty DESC, 
    R.Score DESC
LIMIT 10;