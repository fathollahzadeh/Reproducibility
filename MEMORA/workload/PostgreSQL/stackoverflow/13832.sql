
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.CommentCount,
    COALESCE(VoteCounts.UpVotes, 0) AS UpVotes,
    COALESCE(VoteCounts.DownVotes, 0) AS DownVotes,
    COALESCE(CommentCounts.TotalComments, 0) AS TotalComments,
    U.Reputation AS OwnerReputation,
    U.DisplayName AS OwnerDisplayName,
    P.PostTypeId,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
) VoteCounts ON P.Id = VoteCounts.PostId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
) CommentCounts ON P.Id = CommentCounts.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.CommentCount, 
    U.Reputation, U.DisplayName, P.PostTypeId,
    VoteCounts.UpVotes, VoteCounts.DownVotes, CommentCounts.TotalComments
ORDER BY 
    P.CreationDate DESC;
