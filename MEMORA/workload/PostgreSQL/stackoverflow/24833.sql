
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS ScoreRank,
        COALESCE(V.UpVotes, 0) - COALESCE(V.DownVotes, 0) AS NetVotes,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            PostId) V ON P.Id = V.PostId
),

FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.Author,
        RP.NetVotes,
        RP.AnswerStatus,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY RP.PostId ORDER BY RP.ViewCount DESC) AS TagRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        (SELECT 
            PostId, 
            STRING_AGG(TagName, ', ') AS TagName
         FROM 
            Posts,
            UNNEST(string_to_array(Tags, ',')) AS TagName
         GROUP BY 
            PostId) T ON RP.PostId = T.PostId
    WHERE 
        RP.ViewCount >= (SELECT AVG(ViewCount) FROM Posts)  
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.ViewCount,
    FP.Score,
    FP.Author,
    FP.NetVotes,
    FP.AnswerStatus,
    CASE 
        WHEN FP.TagRank = 1 THEN 'Primary Tag'
        ELSE NULL
    END AS PrimaryTagIndicator
FROM 
    FilteredPosts FP
WHERE 
    (FP.Score >= 10 OR FP.NetVotes > 5)  
    AND FP.AnswerStatus = 'Accepted'
ORDER BY 
    FP.Score DESC, FP.CreationDate ASC;
