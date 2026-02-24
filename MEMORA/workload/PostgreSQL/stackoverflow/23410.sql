
WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 100
),
RecentBadges AS (
    SELECT 
        UserId,
        Name,
        Date,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY Date DESC) AS BadgeRank
    FROM 
        Badges
    WHERE 
        EXTRACT(YEAR FROM Date) = EXTRACT(YEAR FROM CURRENT_DATE)
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
        P.ViewCount,
        PT.Name AS PostType,
        P.Score,
        COALESCE(PT.Name, 'Unknown') AS TypeNameFallback, 
        (SELECT STRING_AGG(DISTINCT TagName, ', ') 
         FROM Tags T WHERE T.Id IN (SELECT UNNEST(string_to_array(P.Tags, ','))::int)) AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment = C.Id::text
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    R.TagName,
    PS.Title,
    PS.TotalComments,
    PS.ViewCount,
    PS.PostType,
    PS.Score,
    PS.TagList,
    CPR.CloseReasons
FROM 
    RankedUsers U
JOIN 
    RecentBadges RB ON U.Id = RB.UserId
JOIN 
    TopTags R ON R.TagCount > (SELECT AVG(TagCount) FROM TopTags) 
JOIN 
    PostSummary PS ON PS.TagList LIKE '%' || R.TagName || '%' 
LEFT JOIN 
    ClosedPostReasons CPR ON CPR.PostId = PS.PostId
WHERE 
    RB.BadgeRank = 1
ORDER BY 
    U.Reputation DESC, PS.Score DESC;
