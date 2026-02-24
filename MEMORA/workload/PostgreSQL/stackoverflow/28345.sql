
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC, P.CreationDate ASC) AS VoteRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.Body, P.Tags, P.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10 
)
SELECT 
    T.OwnerDisplayName,
    T.Title,
    T.Body,
    T.Tags,
    T.UpVotes,
    T.DownVotes,
    T.CommentCount,
    (SELECT 
        COUNT(*) 
     FROM 
        PostHistory PH 
     WHERE 
        PH.PostId = T.PostId AND 
        PH.PostHistoryTypeId IN (10, 11) 
    ) AS CloseReopenCount,
    (SELECT 
        STRING_AGG(B.Name, ', ') 
     FROM 
        Badges B 
     JOIN 
        Users U ON B.UserId = U.Id 
     WHERE 
        U.DisplayName = T.OwnerDisplayName
    ) AS OwnerBadges
FROM 
    TopPosts T
ORDER BY 
    T.UpVotes DESC, 
    T.CommentCount DESC;
