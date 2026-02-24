
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.Score,
        U.DisplayName AS AuthorName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        P.Id, P.Title, P.Tags, P.CreationDate, P.Score, U.DisplayName
),

TagCount AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(P.Tags, '>'))) AS Tag,
        COUNT(*) AS TagFrequency
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        TRIM(UNNEST(STRING_TO_ARRAY(P.Tags, '>')))
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
),

PopularAuthors AS (
    SELECT 
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS QuestionCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.DisplayName
    HAVING 
        COUNT(P.Id) > 10 
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Tags,
    RP.CreationDate,
    RP.Score,
    RP.AuthorName,
    RP.CommentCount,
    TC.Tag AS TopTag,
    TC.TagFrequency,
    PA.DisplayName AS PopularAuthorName,
    PA.TotalScore AS PopularAuthorScore,
    PA.QuestionCount AS PopularAuthorQuestions
FROM 
    RankedPosts RP
LEFT JOIN 
    TagCount TC ON TC.Tag = ANY(STRING_TO_ARRAY(RP.Tags, '>'))
LEFT JOIN 
    PopularAuthors PA ON RP.AuthorName = PA.DisplayName
WHERE 
    RP.PostRank <= 3 
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;
