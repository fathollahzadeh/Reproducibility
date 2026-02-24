
WITH TagCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT S.Tag) AS TagCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users U
    JOIN 
        Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
        ) AS S ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TagCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 0
),

MostActiveTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)

SELECT 
    U.DisplayName AS TopUser,
    U.TagCount,
    U.TotalViews,
    T.TagName AS MostActiveTag,
    T.PostCount,
    T.TotalViews AS TagTotalViews
FROM 
    TopUsers U
JOIN 
    MostActiveTags T ON TRUE
WHERE 
    U.ViewRank <= 5 
ORDER BY 
    U.TotalViews DESC, 
    T.TotalViews DESC;
