
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS AuthorName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.AuthorName,
        RP.CommentCount,
        RP.AnswerCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Posts P ON RP.PostId = P.Id
    LEFT JOIN 
        LATERAL (SELECT TRIM(BOTH '<>' FROM UNNEST(STRING_TO_ARRAY(P.Tags, ','))) AS TagName) AS TagArray ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagArray.TagName
    WHERE 
        RP.UserPostRank <= 5  
    GROUP BY 
        RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.AuthorName, RP.CommentCount, RP.AnswerCount
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.CreationDate,
    FP.AuthorName,
    FP.CommentCount,
    FP.AnswerCount,
    FP.Tags,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    FilteredPosts FP
LEFT JOIN 
    PostHistory PH ON FP.PostId = PH.PostId 
                  AND PH.PostHistoryTypeId IN (4, 5) 
WHERE 
    PH.CreationDate IS NOT NULL
ORDER BY 
    FP.CreationDate DESC;
