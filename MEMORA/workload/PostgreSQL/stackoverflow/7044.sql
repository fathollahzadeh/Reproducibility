
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    T.OwnerDisplayName,
    T.Title,
    T.CreationDate,
    T.UpVotes,
    T.DownVotes,
    T.CommentCount,
    COALESCE(PH.Comment, 'No edits made') AS RecentEditComment
FROM 
    TopPosts T
LEFT JOIN 
    PostHistory PH ON T.PostId = PH.PostId 
                   AND PH.CreationDate = (
                       SELECT MAX(PH2.CreationDate) 
                       FROM PostHistory PH2 WHERE PH2.PostId = T.PostId
                   )
ORDER BY 
    T.UpVotes DESC, T.CommentCount DESC;
