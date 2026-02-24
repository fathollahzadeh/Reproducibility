
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS Downvotes,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    WHERE 
        p.PostTypeId = 1 
),

UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),

TopActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2 
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(P.ViewCount) > 1000 
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)

SELECT 
    RP.Id AS PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.Upvotes,
    RP.Downvotes,
    COALESCE(U.BadgeCount, 0) AS BadgeCount,
    COALESCE(TA.TotalViews, 0) AS TotalViews
FROM 
    RankedPosts RP
LEFT JOIN 
    UserBadges U ON RP.OwnerUserId = U.UserId
LEFT JOIN 
    TopActiveUsers TA ON RP.OwnerUserId = TA.UserId
WHERE 
    RP.rn = 1 
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
