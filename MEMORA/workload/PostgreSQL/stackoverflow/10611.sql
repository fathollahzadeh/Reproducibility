
WITH PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes
    FROM 
        Posts P
        LEFT JOIN Users U ON P.OwnerUserId = U.Id
        LEFT JOIN Votes V ON P.Id = V.PostId
        LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2022-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, P.FavoriteCount, U.Reputation, U.DisplayName
),
PostMetrics AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(FavoriteCount) AS AvgFavoriteCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        SUM(CloseVotes) AS TotalCloseVotes
    FROM 
        PostSummary
)
SELECT 
    PM.TotalPosts,
    PM.AvgViewCount,
    PM.AvgScore,
    PM.AvgAnswerCount,
    PM.AvgCommentCount,
    PM.AvgFavoriteCount,
    PM.TotalUpVotes,
    PM.TotalDownVotes,
    PM.TotalCloseVotes
FROM 
    PostMetrics PM;
