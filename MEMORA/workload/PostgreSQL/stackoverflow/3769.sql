
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.Reputation,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(RP.PostCount, 0) AS TotalPosts,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PC.CommentCount, 0) AS TotalComments
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(Id) AS PostCount
        FROM 
            Posts
        GROUP BY 
            OwnerUserId
    ) RP ON U.Id = RP.OwnerUserId
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostComments PC ON U.Id = PC.PostId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalBadges,
        UA.TotalComments,
        ROW_NUMBER() OVER (ORDER BY UA.TotalPosts DESC, UA.TotalBadges DESC) AS UserRank
    FROM 
        UserActivity UA
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalBadges,
    TU.TotalComments,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    TU.UserRank
FROM 
    TopUsers TU
LEFT JOIN 
    RankedPosts RP ON TU.UserId = RP.OwnerUserId
WHERE 
    TU.UserRank <= 10 
    AND (RP.Score IS NULL OR RP.Score > 10)
ORDER BY 
    TU.UserRank;
