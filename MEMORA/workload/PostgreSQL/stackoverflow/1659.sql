
WITH UserVotes AS (
    SELECT 
        P.Id AS PostId,
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UserVoteTypeCount
    FROM 
        Posts P
    JOIN 
        Votes V ON P.Id = V.PostId
    JOIN 
        Users U ON V.UserId = U.Id
    GROUP BY 
        P.Id, U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(MAX(B.Class), 0) AS HighestBadgeClass,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
FinalResults AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.OwnerDisplayName,
        PD.CommentCount,
        UVote.VoteCount AS TotalVotes,
        UVote.UserVoteTypeCount AS UpVotes,
        PD.HighestBadgeClass
    FROM 
        PostDetails PD
    LEFT JOIN 
        UserVotes UVote ON PD.PostId = UVote.PostId
    WHERE 
        PD.RowNum = 1 AND PD.CommentCount > 0
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.Score,
    FR.ViewCount,
    FR.OwnerDisplayName,
    FR.CommentCount,
    COALESCE(FR.TotalVotes, 0) AS TotalVotes,
    COALESCE(FR.UpVotes, 0) AS UpVotes,
    CASE 
        WHEN FR.HighestBadgeClass = 1 THEN 'Gold'
        WHEN FR.HighestBadgeClass = 2 THEN 'Silver'
        WHEN FR.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS UserBadge
FROM 
    FinalResults FR
ORDER BY 
    FR.Score DESC, FR.CommentCount DESC;
