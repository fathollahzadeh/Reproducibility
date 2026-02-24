
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    hep.Title AS PostTitle,
    hep.CreationDate AS PostDate,
    hep.Score AS PostScore,
    hep.ViewCount AS PostViews,
    hep.CommentCount AS PostComments,
    ue.DisplayName AS UserName,
    ue.TotalBounty AS UserTotalBounty,
    ue.PostsCount AS UserPostsCount,
    ue.TotalComments AS UserTotalComments,
    hep.ScoreCategory
FROM 
    HighScoringPosts hep
JOIN 
    Users u ON hep.PostId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    hep.ScoreCategory = 'High'
ORDER BY 
    hep.Score DESC, ue.TotalBounty DESC
FETCH FIRST 100 ROWS ONLY;
