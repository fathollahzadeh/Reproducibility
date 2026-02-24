
WITH RankedPosts AS (
  SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
  FROM 
    Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
  WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND p.PostTypeId = 1
  GROUP BY 
    p.Id, p.Title, p.ViewCount, p.OwnerUserId
),
UserAggregates AS (
  SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    SUM(vBounty.BountyAmount) AS TotalBountyWon,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    COUNT(DISTINCT p.Id) FILTER (WHERE p.AcceptedAnswerId IS NOT NULL) AS TotalAcceptedAnswers
  FROM 
    Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes vBounty ON p.Id = vBounty.PostId AND vBounty.VoteTypeId IN (8, 9)
  WHERE 
    u.Reputation > 5000
  GROUP BY 
    u.Id, u.DisplayName, u.Reputation
)
SELECT 
  ru.DisplayName AS UserDisplayName,
  ru.Reputation,
  COUNT(DISTINCT rp.PostId) AS TotalPosts,
  SUM(rp.ViewCount) AS TotalViews,
  SUM(ua.TotalBountyWon) AS TotalBounty,
  MAX(ua.TotalQuestions) AS TotalQuestions,
  MAX(ua.TotalAcceptedAnswers) AS TotalAcceptedQuestions
FROM 
  RankedPosts rp
  JOIN UserAggregates ua ON rp.PostId = ua.UserId
  JOIN Users ru ON ua.UserId = ru.Id
GROUP BY 
  ru.Id, ru.DisplayName, ru.Reputation
ORDER BY 
  TotalViews DESC
LIMIT 10;
