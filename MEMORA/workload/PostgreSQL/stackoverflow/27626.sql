
WITH StringStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        LENGTH(P.Body) AS BodyLength,
        LENGTH(P.Title) AS TitleLength,
        CARDINALITY(string_to_array(SUBSTRING(P.Tags FROM 2 FOR LENGTH(P.Tags) - 2), '><')) AS TagCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
StringPerformance AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        BodyLength,
        TitleLength,
        TagCount,
        CommentCount,
        VoteCount,
        CASE 
            WHEN BodyLength > 2000 THEN 'Long Body'
            WHEN BodyLength BETWEEN 1000 AND 2000 THEN 'Medium Body'
            ELSE 'Short Body'
        END AS BodySizeCategory,
        CASE 
            WHEN TitleLength > 100 THEN 'Long Title'
            ELSE 'Short Title'
        END AS TitleSizeCategory
    FROM 
        StringStats
)
SELECT 
    BodySizeCategory,
    TitleSizeCategory,
    COUNT(*) AS PostCount,
    AVG(CommentCount) AS AvgComments,
    AVG(VoteCount) AS AvgVotes
FROM 
    StringPerformance
GROUP BY 
    BodySizeCategory, TitleSizeCategory
ORDER BY 
    BodySizeCategory, TitleSizeCategory;
