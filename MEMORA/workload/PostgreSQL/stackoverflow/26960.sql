WITH TagSummary AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        ARRAY_AGG(DISTINCT U.DisplayName) AS Contributors,
        AVG(P.CreationDate::date - U.CreationDate::date) AS AvgPostAge 
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY T.TagName ORDER BY P.ViewCount DESC) AS RN
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1 
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalScore,
    TS.Contributors,
    TS.AvgPostAge,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViews,
    TP.CreationDate AS TopPostDate
FROM 
    TagSummary TS
LEFT JOIN 
    TopPosts TP ON TS.TagName = SPLIT_PART(TP.Tags, ',', 1) 
WHERE 
    TP.RN = 1
ORDER BY 
    TS.TotalScore DESC, TS.PostCount DESC;