WITH RecursivePostHistory AS (
    SELECT p.Id, 
           p.Title,
           p.CreationDate,
           ph.CreationDate AS HistoryCreationDate,
           pt.Name AS PostTypeName,
           ph.UserDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    INNER JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 10)  
),
FilteredPosts AS (
    SELECT Id, 
           Title, 
           CreationDate,
           HistoryCreationDate,
           PostTypeName,
           UserDisplayName
    FROM RecursivePostHistory
    WHERE HistoryRank = 1  
),
UserStatistics AS (
    SELECT u.Id AS UserId, 
           u.DisplayName,
           SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotesReceived,
           COUNT(DISTINCT vs.VoteTypeId) AS UniqueVoteTypes
    FROM Users u
    LEFT JOIN (
        SELECT Post.OwnerUserId AS UserId,
               COUNT(v.Id) AS VoteCount,
               v.VoteTypeId
        FROM Posts Post
        LEFT JOIN Votes v ON Post.Id = v.PostId
        GROUP BY Post.OwnerUserId, v.VoteTypeId
    ) vs ON u.Id = vs.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId,
           DisplayName,
           TotalVotesReceived,
           Dense_Rank() OVER (ORDER BY TotalVotesReceived DESC) AS VoteRank
    FROM UserStatistics
    WHERE TotalVotesReceived > 0
)
SELECT fp.Title,
       fp.CreationDate,
       fp.PostTypeName,
       fp.UserDisplayName,
       tu.DisplayName AS TopUser,
       tu.TotalVotesReceived
FROM FilteredPosts fp
LEFT JOIN TopUsers tu ON fp.UserDisplayName = tu.DisplayName
WHERE fp.PostTypeName = 'Question' 
AND EXISTS (
    SELECT 1 
    FROM Comments c 
    WHERE c.PostId = fp.Id
    AND c.Score > 0
)
ORDER BY fp.CreationDate DESC;