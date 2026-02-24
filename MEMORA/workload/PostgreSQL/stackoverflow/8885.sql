
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.PostTypeId
),
RecentPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.CreationDate, 
        RP.OwnerDisplayName, 
        RP.CommentCount, 
        RP.AnswerCount
    FROM 
        RankedPosts RP 
    WHERE 
        RP.RN <= 10  
),
VoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
FinalResult AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.AnswerCount,
        COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
        COALESCE(VS.DownVotes, 0) AS TotalDownVotes
    FROM 
        RecentPosts RP
    LEFT JOIN 
        VoteSummary VS ON RP.PostId = VS.PostId
)
SELECT 
    FR.PostId, 
    FR.Title, 
    FR.CreationDate, 
    FR.OwnerDisplayName,
    FR.CommentCount, 
    FR.AnswerCount, 
    FR.TotalUpVotes, 
    FR.TotalDownVotes
FROM 
    FinalResult FR
ORDER BY 
    FR.CreationDate DESC;
