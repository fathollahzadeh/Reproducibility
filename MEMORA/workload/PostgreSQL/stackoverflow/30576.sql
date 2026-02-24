WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
TopScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostAnalytics AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.OwnerReputation,
        COUNT(CM.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        TopScoringPosts PS
    LEFT JOIN 
        Comments CM ON PS.PostId = CM.PostId
    LEFT JOIN 
        Votes V ON PS.PostId = V.PostId
    GROUP BY 
        PS.PostId, PS.Title, PS.Score, PS.ViewCount, PS.OwnerReputation
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS MaxBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostBadges AS (
    SELECT 
        PA.PostId,
        CASE 
            WHEN UB.BadgeCount >= 5 THEN 'Gold Badge Holder'
            WHEN UB.BadgeCount >= 3 THEN 'Silver Badge Holder'
            WHEN UB.BadgeCount >= 1 THEN 'Bronze Badge Holder'
            ELSE 'No Badges'
        END AS BadgeStatus
    FROM 
        PostAnalytics PA
    JOIN 
        Users U ON PA.OwnerReputation = U.Reputation
    JOIN 
        UserBadges UB ON U.Id = UB.UserId
)
SELECT 
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.CommentCount,
    PA.VoteCount,
    PA.TotalUpvotes,
    PA.TotalDownvotes,
    PB.BadgeStatus
FROM 
    PostAnalytics PA
LEFT JOIN 
    PostBadges PB ON PA.PostId = PB.PostId
WHERE 
    PA.Score > 0
ORDER BY 
    PA.Score DESC, PA.ViewCount DESC;
