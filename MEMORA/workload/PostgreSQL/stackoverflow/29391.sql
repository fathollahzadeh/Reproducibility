WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class AS BadgeClass,
        B.Date AS BadgeDate,
        COUNT(*) OVER (PARTITION BY U.Id) AS TotalBadges
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
),
FrequentTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TotalPosts
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, '><')::int[])
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(*) > 50
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
    HAVING 
        COUNT(DISTINCT P.Id) > 10
),
PostEditHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditsCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
),
HighlyEditedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        E.EditsCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        PostEditHistory E ON P.Id = E.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        E.EditsCount > 10
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalBadges,
    T.TagName,
    T.TotalPosts,
    A.TotalPosts AS UserPosts,
    A.TotalComments AS UserComments,
    A.TotalViews AS UserViews,
    H.PostId,
    H.Title AS HighlyEditedPostTitle,
    H.EditsCount AS TotalEdits,
    H.OwnerDisplayName,
    H.OwnerReputation
FROM 
    UserBadges U
JOIN 
    FrequentTags T ON T.TagName LIKE '%SQL%'
JOIN 
    ActiveUsers A ON U.UserId = A.UserId
LEFT JOIN 
    HighlyEditedPosts H ON H.OwnerDisplayName = U.DisplayName
ORDER BY 
    U.TotalBadges DESC, A.TotalPosts DESC;