WITH TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
), 
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
RecentActivities AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PH.CreationDate,
        PH.Comment,
        P.Title AS PostTitle
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    TU.PostCount,
    PT.TagName AS PopularTag,
    PT.PostCount AS TagPostCount,
    PT.TotalViews AS TagTotalViews,
    RA.UserId AS ActivityUserId,
    RA.PostTitle,
    RA.Comment,
    RA.CreationDate AS ActivityDate
FROM 
    TopUsers TU
CROSS JOIN 
    PopularTags PT
LEFT JOIN 
    RecentActivities RA ON TU.UserId = RA.UserId
ORDER BY 
    TU.TotalUpVotes DESC, 
    PT.PostCount DESC, 
    RA.CreationDate DESC;