WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FinalPostStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        pu.UserRank,
        pd.TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY pu.UserId ORDER BY pd.CreationDate DESC) AS UserPostRank
    FROM PostDetails pd
    JOIN TopUsers pu ON pd.OwnerUserId = pu.UserId
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.CreationDate,
    fps.CommentCount,
    fps.OwnerDisplayName,
    fps.TotalBounties,
    CASE 
        WHEN fps.UserPostRank = 1 THEN 'Newest Post'
        WHEN fps.UserPostRank <= 5 THEN 'Top 5 Recent Posts'
        ELSE 'Past Posts'
    END AS PostStatus
FROM FinalPostStats fps
WHERE fps.CommentCount > 10
ORDER BY fps.TotalBounties DESC, fps.CreationDate DESC
LIMIT 20;