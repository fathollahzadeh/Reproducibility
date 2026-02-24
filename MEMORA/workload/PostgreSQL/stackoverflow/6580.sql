
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS OwnerRank
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        OwnerRank <= 5
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(PT.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts PT ON PT.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViewCount,
    TP.OwnerDisplayName,
    TT.TagName AS PopularTag,
    TT.PostCount AS TagPostCount
FROM 
    TopPosts TP
JOIN 
    TopTags TT ON TT.TagName = ANY (string_to_array(TP.Title, ' ')) 
ORDER BY 
    TP.Score DESC, 
    TT.PostCount DESC;
