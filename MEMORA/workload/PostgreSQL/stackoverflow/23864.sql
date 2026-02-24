
WITH MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScores,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScores,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation IS NOT NULL
    GROUP BY 
        U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 10
),
LatestPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastActivityDate,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        CASE
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed'
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Open'
        END AS PostStatus,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS ActivityRank,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    GROUP BY 
        P.Id, P.Title, P.LastActivityDate, P.ClosedDate, P.AcceptedAnswerId, P.OwnerUserId
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.PostCount,
    A.TotalViews,
    A.PositiveScores,
    A.NegativeScores,
    T.TagName,
    T.TotalViews AS TagTotalViews,
    T.PostCount AS TagPostCount,
    L.PostId,
    L.Title,
    L.LastActivityDate,
    L.CommentCount,
    L.BadgeCount,
    L.PostStatus
FROM 
    MostActiveUsers A
CROSS JOIN 
    TopPostTags T
JOIN 
    LatestPostActivity L ON A.UserId = L.OwnerUserId 
WHERE 
    A.Rank <= 10 AND L.ActivityRank = 1
    AND (L.CommentCount > 5 OR L.BadgeCount > 2)
    AND (L.PostStatus = 'Open' OR L.PostStatus = 'Answered')
ORDER BY 
    A.TotalViews DESC, 
    T.TotalViews DESC, 
    L.LastActivityDate DESC;
