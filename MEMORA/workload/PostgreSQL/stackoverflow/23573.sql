WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
        AND U.Location IS NOT NULL
        AND U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.OwnerUserId
),
RecentComments AS (
    SELECT 
        C.UserId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        C.UserId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        COALESCE(R.CommentCount, 0) AS CommentCount,
        U.Reputation,
        U.UserRank,
        B.BadgeNames,
        P.TotalScore,
        P.AvgViewCount
    FROM 
        RankedUsers U
    LEFT JOIN 
        PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        UserBadges B ON U.Id = B.UserId
    LEFT JOIN 
        RecentComments R ON U.Id = R.UserId
)
SELECT 
    CS.UserId,
    CS.DisplayName,
    CS.PostCount,
    CS.BadgeCount,
    CS.CommentCount,
    CS.Reputation,
    CS.UserRank,
    COALESCE(CASE WHEN CS.PostCount < 5 THEN 'No Posts' ELSE NULL END, 'Active User') AS UserStatus,
    CASE 
        WHEN CS.TotalScore > 100 THEN 'Top Contributor'
        WHEN CS.TotalScore > 0 THEN 'Contributor'
        ELSE 'New User'
    END AS ContributionLevel,
    ARRAY_AGG(DISTINCT T.TagName) AS PopularTags
FROM 
    CombinedStats CS
LEFT JOIN 
    Posts P ON CS.UserId = P.OwnerUserId
LEFT JOIN 
    Tags T ON T.WikiPostId = P.Id
WHERE 
    CS.Reputation >= 1000
GROUP BY 
    CS.UserId, CS.DisplayName, CS.PostCount, CS.BadgeCount, CS.CommentCount, 
    CS.Reputation, CS.UserRank, CS.TotalScore 
ORDER BY 
    CS.UserRank
LIMIT 10;