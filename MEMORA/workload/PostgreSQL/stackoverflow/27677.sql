
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
),

TagSummary AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, '>'))) AS TagName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalScore,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        TagSummary
)

SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalScore,
    TT.AverageScore,
    P.Title,
    P.Body,
    P.OwnerName,
    P.CreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.AnswerCount AS PostAnswerCount
FROM 
    TopTags TT
JOIN 
    RankedPosts P ON TT.TagName = ANY(string_to_array(P.Tags, '>'))
WHERE 
    TT.Rank <= 5 
ORDER BY 
    TT.TotalScore DESC, P.CreationDate DESC;
