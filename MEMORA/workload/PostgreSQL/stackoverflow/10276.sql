
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.ID) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
VotingDetails AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.OwnerDisplayName,
    PD.CommentCount,
    VD.VoteCount,
    VD.UpVoteCount,
    VD.DownVoteCount,
    PD.BadgeCount
FROM 
    PostDetails PD
LEFT JOIN 
    VotingDetails VD ON PD.PostId = VD.PostId
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC
LIMIT 100;
