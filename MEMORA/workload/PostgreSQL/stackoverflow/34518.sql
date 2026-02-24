
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Author,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
      AND 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopAnsweredPosts AS (
    SELECT 
        R.PostId,
        R.Title,
        R.CreationDate,
        R.Score,
        R.Author,
        R.ViewCount,
        P.AnswerCount,
        COALESCE(C.CloseReason, 'No Close Reason') AS CloseReason
    FROM 
        RankedPosts R
    LEFT JOIN (
        SELECT 
            PH.PostId,
            STRING_AGG(CRT.Name, ', ') AS CloseReason
        FROM 
            PostHistory PH
        JOIN 
            CloseReasonTypes CRT ON PH.Comment = CRT.Id::TEXT
        WHERE 
            PH.PostHistoryTypeId = 10
        GROUP BY 
            PH.PostId
    ) C ON R.PostId = C.PostId
    JOIN 
        Posts P ON R.PostId = P.Id
    WHERE 
        R.Rank <= 5 
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts P
    JOIN 
        UNNEST(STRING_TO_ARRAY(P.Tags, ',')) AS T(TagName) ON TRUE
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    R.Author,
    R.Title,
    R.CreationDate,
    R.Score,
    R.ViewCount,
    T.TagName AS PopularTag,
    COUNT(C.ID) FILTER (WHERE C.UserId IS NOT NULL) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounties
FROM 
    TopAnsweredPosts R
LEFT JOIN 
    Comments C ON R.PostId = C.PostId
LEFT JOIN 
    Votes V ON R.PostId = V.PostId AND V.VoteTypeId = 8 
LEFT JOIN 
    PopularTags T ON TRUE
GROUP BY 
    R.Author, R.Title, R.CreationDate, R.Score, R.ViewCount, T.TagName
ORDER BY 
    R.Score DESC, R.ViewCount DESC;
