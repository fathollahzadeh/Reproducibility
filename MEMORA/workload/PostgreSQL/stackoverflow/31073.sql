
WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, Score, OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY Score DESC) AS Rank
    FROM Posts
    WHERE PostTypeId = 2  
),
PostAnalytics AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           u.DisplayName AS OwnerName,
           COALESCE(ph.Rank, 0) AS AnswerRank,
           COALESCE(ph.Score, 0) AS TopAnswerScore,
           COUNT(c.Id) AS CommentCount,
           SUM(v.BountyAmount) AS TotalBounty,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN RecursivePostHierarchy ph ON p.Id = ph.ParentId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, u.DisplayName, ph.Rank, ph.Score
),
ClosePostAnalysis AS (
    SELECT p.Id AS PostId, 
           COUNT(ph.Id) AS CloseReasonCount,
           STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  
    LEFT JOIN CloseReasonTypes ct ON CAST(ph.Comment AS INTEGER) = ct.Id
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id
)
SELECT pa.PostId, 
       pa.Title, 
       pa.CreationDate, 
       pa.OwnerName,
       pa.AnswerRank,
       pa.TopAnswerScore,
       pa.CommentCount,
       pa.TotalBounty,
       pa.Upvotes,
       cpa.CloseReasonCount,
       cpa.CloseReasons
FROM PostAnalytics pa
LEFT JOIN ClosePostAnalysis cpa ON pa.PostId = cpa.PostId
WHERE pa.CommentCount > 5  
  AND (cpa.CloseReasonCount IS NULL OR cpa.CloseReasonCount = 0)  
ORDER BY pa.Upvotes DESC, pa.CreationDate DESC;
