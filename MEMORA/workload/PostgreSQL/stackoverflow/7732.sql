
WITH RankedPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        U.DisplayName AS OwnerName, 
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score
),
PopularTags AS (
    SELECT 
        DISTINCT UNNEST(STRING_TO_ARRAY(T.Tags, '><')) AS Tag
    FROM 
        Posts T
    WHERE 
        T.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || '<' || T.TagName || '>%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    RP.OwnerName, 
    RP.Title, 
    TAGS.TagName, 
    RP.CommentCount, 
    RP.Score,
    RP.CreationDate
FROM 
    RankedPosts RP
JOIN 
    TagStatistics TAGS ON RP.Title ILIKE '%' || TAGS.TagName || '%'
WHERE 
    RP.PostRank <= 3
ORDER BY 
    RP.Score DESC, 
    RP.CommentCount DESC;
