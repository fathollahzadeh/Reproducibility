WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostEngagement AS (
    SELECT 
        PS.PostId,
        PS.PostTypeId,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.OwnerReputation,
        PS.OwnerDisplayName,
        COALESCE(VS.UpVotes, 0) AS UpVotes,
        COALESCE(VS.DownVotes, 0) AS DownVotes
    FROM 
        PostStats PS
    LEFT JOIN 
        VoteStats VS ON PS.PostId = VS.PostId
)
SELECT 
    PostTypeId,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    COUNT(*) AS TotalPosts
FROM 
    PostEngagement
GROUP BY 
    PostTypeId
ORDER BY 
    PostTypeId;