WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS rn,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate BETWEEN '2023-01-01' AND '2023-10-01'
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(DISTINCT P.Id) > 5
),
PostWithComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentsCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
FinalResult AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerName,
        RP.Score,
        RP.ViewCount,
        RP.Upvotes,
        RP.Downvotes,
        COALESCE(PWC.CommentsCount, 0) AS CommentsCount,
        (SELECT STRING_AGG(TagName, ', ') FROM PopularTags WHERE PostsCount > 5) AS PopularTags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostWithComments PWC ON RP.PostId = PWC.PostId
    WHERE 
        RP.rn <= 5
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.OwnerName,
    FR.Score,
    FR.ViewCount,
    FR.Upvotes,
    FR.Downvotes,
    FR.CommentsCount,
    FR.PopularTags
FROM 
    FinalResult FR
ORDER BY 
    FR.Score DESC, FR.ViewCount DESC;
