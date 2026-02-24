
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostWithComments AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.OwnerDisplayName,
        COALESCE(PC.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts RP
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) PC ON RP.PostId = PC.PostId
    WHERE 
        RP.Rank <= 5
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts P
    JOIN 
        Tags T ON T.Id = P.Id
    GROUP BY 
        T.TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 10
)
SELECT 
    PWC.PostId,
    PWC.Title,
    PWC.Score,
    PWC.OwnerDisplayName,
    PWC.CommentCount,
    TT.TagName
FROM 
    PostWithComments PWC
CROSS JOIN 
    TopTags TT
ORDER BY 
    PWC.Score DESC, 
    PWC.CommentCount DESC;
