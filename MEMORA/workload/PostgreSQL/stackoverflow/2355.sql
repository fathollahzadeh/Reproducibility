WITH UserReputation AS (
    SELECT Id, Reputation, DisplayName, 
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),

PopularPosts AS (
    SELECT Id, PostTypeId, OwnerUserId, Score, ViewCount, 
           RANK() OVER (PARTITION BY PostTypeId ORDER BY Score DESC) AS PopularityRank
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),

CommentsCount AS (
    SELECT PostId, COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
),

CloseReasons AS (
    SELECT ph.PostId, 
           STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
)

SELECT ur.DisplayName,
       ur.Reputation,
       pp.Id AS PopularPostId,
       pp.Score,
       pp.ViewCount,
       COALESCE(cc.TotalComments, 0) AS CommentCount,
       cr.CloseReasonNames
FROM UserReputation ur
LEFT JOIN PopularPosts pp ON ur.Id = pp.OwnerUserId
LEFT JOIN CommentsCount cc ON pp.Id = cc.PostId
LEFT JOIN CloseReasons cr ON pp.Id = cr.PostId
WHERE pp.PopularityRank <= 10
ORDER BY ur.Reputation DESC, pp.Score DESC;