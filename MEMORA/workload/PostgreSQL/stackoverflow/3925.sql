
WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount,
        COALESCE(MAX(PH.CreationDate), '1900-01-01'::DATE) AS LastEditDate,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title 
),
CommentsForTopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY PS.PostId ORDER BY C.CreationDate DESC) AS RecentCommentRank,
        C.UserDisplayName AS LastCommenter
    FROM 
        PostStats PS
    LEFT JOIN 
        Comments C ON PS.PostId = C.PostId
    WHERE 
        PS.RankByScore <= 10
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    COALESCE(CFTP.LastCommenter, 'No Comments') AS LastCommenter,
    UVC.DisplayName AS CommenterDisplayName,
    UVC.UpVotes,
    UVC.DownVotes,
    CASE 
        WHEN PS.LastEditDate > '2020-01-01' THEN 'Recently Updated'
        ELSE 'Not Updated Recently'
    END AS UpdateStatus
FROM 
    PostStats PS
LEFT JOIN 
    CommentsForTopPosts CFTP ON PS.PostId = CFTP.PostId
LEFT JOIN 
    UserVoteCounts UVC ON CFTP.LastCommenter = UVC.DisplayName
WHERE 
    PS.CommentCount > 0
ORDER BY 
    PS.CommentCount DESC, PS.PostId;
