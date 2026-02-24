
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        U.DisplayName AS Author,
        P.Tags,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory ph ON P.Id = ph.PostId 
                        AND ph.CreationDate = (SELECT MAX(ph2.CreationDate) 
                                                FROM PostHistory ph2 
                                                WHERE ph2.PostId = P.Id) 
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND P.PostTypeId = 1 
),

TagUsage AS (
    SELECT 
        unnest(string_to_array(P.Tags, ',')) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND P.PostTypeId = 1
    GROUP BY 
        TagName
),

TagStatistics AS (
    SELECT 
        T.TagName,
        T.Count AS TotalPosts,
        COALESCE(TU.UsageCount, 0) AS UsedInQuestions,
        COALESCE(CAST(TU.UsageCount AS FLOAT) / NULLIF(T.Count, 0), 0) * 100 AS UsagePercentage
    FROM 
        Tags T
    LEFT JOIN 
        TagUsage TU ON T.TagName = TU.TagName
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.Author,
    PD.ViewCount,
    PD.Score,
    PD.LastEditor,
    PD.LastEditDate,
    TS.TagName,
    TS.TotalPosts,
    TS.UsedInQuestions,
    TS.UsagePercentage
FROM 
    PostDetails PD
JOIN 
    TagStatistics TS ON TS.TagName = ANY(string_to_array(PD.Tags, ','))
ORDER BY 
    PD.Score DESC, 
    PD.ViewCount DESC;
