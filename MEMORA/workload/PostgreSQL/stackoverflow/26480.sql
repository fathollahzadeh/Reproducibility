
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS AuthorName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(TRIM(value), ', ') AS Tags
    FROM 
        Posts P,
        UNNEST(STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS value
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.AuthorName,
    RP.Upvotes,
    RP.Downvotes,
    RP.CommentCount,
    PT.Tags,
    DENSE_RANK() OVER (ORDER BY RP.Upvotes - RP.Downvotes DESC) AS PopularityRank
FROM 
    RankedPosts RP
JOIN 
    PostTags PT ON RP.PostId = PT.PostId
WHERE 
    RP.PostRank = 1 
ORDER BY 
    PopularityRank
LIMIT 10;
