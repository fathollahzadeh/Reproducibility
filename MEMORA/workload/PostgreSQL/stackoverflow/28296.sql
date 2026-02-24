WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY P.Score DESC, P.ViewCount DESC) AS RankByPerformance
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 
        AND P.Score > 10 
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
AggregatedData AS (
    SELECT 
        U.Location,
        COUNT(RP.PostId) AS NumberOfQuestions,
        AVG(RP.Score) AS AverageScore,
        SUM(RP.AnswerCount) AS TotalAnswers,
        SUM(RP.ViewCount) AS TotalViews
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerDisplayName = U.DisplayName
    GROUP BY 
        U.Location
),
PopularTags AS (
    SELECT 
        DISTINCT UNNEST(string_to_array(RP.Tags, '><')) AS Tag
    FROM 
        RankedPosts RP
    WHERE 
        RankByPerformance <= 5 
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
)
SELECT 
    AD.Location,
    AD.NumberOfQuestions,
    AD.AverageScore,
    AD.TotalAnswers,
    AD.TotalViews,
    TP.Tag,
    TP.TagCount
FROM 
    AggregatedData AD
JOIN 
    TagPopularity TP ON AD.Location = TP.Tag
ORDER BY 
    AD.NumberOfQuestions DESC, 
    AD.AverageScore DESC
LIMIT 10;