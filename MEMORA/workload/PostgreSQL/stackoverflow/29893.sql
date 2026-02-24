WITH TagDetails AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
),
PopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        PositiveScoreCount,
        NegativeScoreCount,
        RANK() OVER (ORDER BY PostCount DESC, PositiveScoreCount DESC) AS PopularityRank
    FROM 
        TagDetails
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        T.TagName,
        P.ViewCount,
        P.Score
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1  
    ORDER BY 
        P.ViewCount DESC
    LIMIT 10
)
SELECT 
    PT.TagId,
    PT.TagName,
    PT.PostCount,
    PT.PositiveScoreCount,
    PT.NegativeScoreCount,
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score
FROM 
    PopularTags PT
JOIN 
    TopPosts TP ON TP.TagName = PT.TagName
WHERE 
    PT.PopularityRank <= 5  
ORDER BY 
    PT.PopularityRank, TP.ViewCount DESC;