
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.PostTypeId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        CommentCount,
        VoteCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Author,
    FP.CommentCount,
    FP.VoteCount,
    FP.UpVotes,
    FP.DownVotes,
    CASE 
        WHEN FP.UpVotes > FP.DownVotes THEN 'Positive'
        WHEN FP.UpVotes < FP.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    FilteredPosts FP
ORDER BY 
    FP.CreationDate DESC;
