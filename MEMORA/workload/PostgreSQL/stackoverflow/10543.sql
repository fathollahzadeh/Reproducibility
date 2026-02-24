
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteStatistics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        PD.OwnerDisplayName,
        PD.OwnerReputation,
        UV.TotalVotes,
        UV.VoteCount,
        UV.AcceptedVoteCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        UserVotes UV ON PD.OwnerDisplayName = UV.DisplayName
)
SELECT 
    VS.Title,
    VS.CreationDate,
    VS.Score,
    VS.ViewCount,
    VS.AnswerCount,
    VS.CommentCount,
    VS.OwnerDisplayName,
    VS.OwnerReputation,
    VS.TotalVotes,
    VS.VoteCount,
    VS.AcceptedVoteCount
FROM 
    VoteStatistics VS
ORDER BY 
    VS.Score DESC, VS.ViewCount DESC
LIMIT 100;
