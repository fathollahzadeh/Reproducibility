WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCount,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
    WHERE 
        PostsCount > 5
),
CommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    cs.TotalComments,
    cs.AvgCommentScore,
    CASE 
        WHEN cs.TotalComments IS NULL THEN 'No comments' 
        ELSE 'Has comments' 
    END AS CommentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentStats cs ON rp.PostId = cs.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
WHERE 
    rp.PostRank <= 10
ORDER BY 
    rp.CreationDate DESC;