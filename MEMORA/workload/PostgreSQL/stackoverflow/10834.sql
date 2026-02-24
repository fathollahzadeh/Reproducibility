WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(U.Reputation, 0) AS OwnerReputation,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    VS.TotalUpVotes,
    VS.TotalDownVotes,
    PS.LastEditDate
FROM 
    PostStatistics PS
LEFT JOIN 
    VoteSummary VS ON PS.PostId = VS.PostId
ORDER BY 
    PS.ViewCount DESC
LIMIT 100;