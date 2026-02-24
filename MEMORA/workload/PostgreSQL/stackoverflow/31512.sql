
WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PopularTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    PT.TagName AS PopularTag,
    PT.TotalViews AS TagTotalViews,
    CASE 
        WHEN RP.Score IS NULL THEN 'No Score'
        ELSE CAST(RP.Score AS TEXT)
    END AS RecentPostScore
FROM 
    Users U
LEFT JOIN 
    UserBadgeCount UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentPostRank = 1
LEFT JOIN 
    PopularTags PT ON RP.Title LIKE CONCAT('%', PT.TagName, '%')
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    BadgeCount DESC;
