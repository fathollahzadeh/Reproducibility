WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        U.Reputation,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        LENGTH(P.Body) AS BodyLength,
        LENGTH(P.Title) AS TitleLength,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        P.CommentCount,
        P.FavoriteCount,
        P.ClosedDate,
        ARRAY_LENGTH(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'), 1) AS TagCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
TagConversion AS (
    SELECT 
        P.PostId,
        P.Author,
        P.PostType,
        P.BodyLength,
        P.TitleLength,
        P.TagCount,
        STRING_AGG(T.TagName, ', ') AS TagList
    FROM 
        PostDetails P
    LEFT JOIN 
        Tags T ON (T.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')))  
    GROUP BY 
        P.PostId, P.Author, P.PostType, P.BodyLength, P.TitleLength, P.TagCount
)
SELECT 
    TC.PostId,
    TC.Author,
    TC.PostType,
    TC.BodyLength,
    TC.TitleLength,
    TC.TagCount,
    TC.TagList,
    COUNT(C.Id) AS CommentCount,  
    SUM(CASE WHEN C.Score > 0 THEN 1 ELSE 0 END) AS Upvotes,  
    SUM(CASE WHEN C.Score < 0 THEN 1 ELSE 0 END) AS Downvotes  
FROM 
    TagConversion TC
LEFT JOIN 
    Comments C ON C.PostId = TC.PostId
GROUP BY 
    TC.PostId, TC.Author, TC.PostType, TC.BodyLength, TC.TitleLength, TC.TagCount, TC.TagList
ORDER BY 
    TC.BodyLength DESC, TC.TitleLength DESC;