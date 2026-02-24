
WITH TagCounts AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        Id AS PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag, 
        COUNT(DISTINCT PostId) AS PostCount, 
        COUNT(*) AS TotalOccurrences
    FROM 
        TagCounts
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        TotalOccurrences,
        ROW_NUMBER() OVER (ORDER BY TotalOccurrences DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        TotalOccurrences > 1  
),
PopularUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBadgeClass,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    T.Tag, 
    T.PostCount, 
    T.TotalOccurrences,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.TotalBadgeClass AS UserTotalBadgeClass
FROM 
    TopTags T
JOIN 
    PopularUsers U ON U.PostCount > 1  
WHERE 
    T.TagRank <= 10  
ORDER BY 
    T.TotalOccurrences DESC;
